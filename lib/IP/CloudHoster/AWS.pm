package IP::CloudHoster::AWS;
use strict;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use Future;
use NetAddr::IP;
use IP::CloudHoster::Info;
use JSON 'decode_json';
use Future::SharedResource 'shared_resource';

our $VERSION = '0.01';
our $aws_ip_range_url = 'https://ip-ranges.amazonaws.com/ip-ranges.json';

has 'aws_ip_range_url' => (
    is => 'rw',
    default => $aws_ip_range_url,
);

has 'ua' => (
    is => 'lazy',
    default => sub {
        require Future::HTTP;
        Future::HTTP->new(),
    },
);

# This is to prevent a thundering herd when multiple requests are made
has 'inflight_requests' => (
    is => 'ro',
    default => sub { {} },
);

has '_aws_ip_ranges' => (
    is => 'rw',
);

# Also, can we turn the UA into a queueing resource with a similar
# approach?

sub retrieve_aws_ips( $self, $address, $ua ) {
    # Should we canonicalize $address?

    # Only request the resource once, even if there are multiple calls
    # while the request is still outstanding
    shared_resource(\($self->inflight_requests->{ $address }))
    ->fetch( sub { $ua->http_get( $address ) })
}

sub ip_ranges_json( $self, %options ) {
    my $res;

    $options{ ua } ||= $self->ua;
    $options{ aws_ip_range_url } ||= $self->aws_ip_range_url;

    my $r = $self->_aws_ip_ranges;
    if( $r ) {
        $res = Future->done( $r )

    } else {
        $res = $self->retrieve_aws_ips(
            $options{ aws_ip_range_url },
            $options{ ua }
        )->then( sub {
            my( $body, $headers ) = @_;
            my $json = decode_json( $body );
            Future->done( $json )
        });
    };

    $res
}

sub parse_ip_ranges( $self, $json ) {
    my @ip_ranges;
    for my $e (@{ $json->{prefixes} }) {
        my $entry = {
            %$e,
            provider => 'amazon',
            range => NetAddr::IP->new( $e->{ ip_prefix } ),
        };

        push @ip_ranges, $entry;
    };

    $self->_aws_ip_ranges( \@ip_ranges );
    return Future->done( $self->_aws_ip_ranges() );
}

sub ip_ranges( $self, %options ) {
    my $res;

    my $r = $self->_aws_ip_ranges;
    if( $r ) {
        $res = Future->done( $r )

    } else {
        $res = $self->ip_ranges_json(
            %options
        )->then( sub( $data ) {
            $self->parse_ip_ranges( $data );
        });
    };

    $res
}

sub identify( $self, $ip, %options ) {
    $ip = NetAddr::IP->new( $ip );
    $self->ip_ranges( %options )->then(sub {
        my( $ip_ranges ) = @_;

        for my $prefix (@$ip_ranges) {
            if( $ip->within( $prefix->{range})) {
                return Future->done(IP::CloudHoster::Info->new($prefix))
            };
        };

        return Future->fail()
    });
}

1