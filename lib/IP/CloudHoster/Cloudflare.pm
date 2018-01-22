package IP::CloudHoster::Cloudflare;
use strict;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use Future;
use NetAddr::IP;
use IP::CloudHoster::Info;
use Future::SharedResource 'shared_resource';

our $VERSION = '0.01';
our @ip_range_urls = qw(
    https://www.cloudflare.com/ips-v4
    https://www.cloudflare.com/ips-v6
);

has 'ip_range_urls' => (
    is => 'lazy',
    default => sub { [@ip_range_urls]},
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

has '_ip_ranges' => (
    is => 'rw',
);

# Also, can we turn the UA into a queueing resource with a similar
# approach?

sub retrieve_ips( $self, $address, $ua ) {
    # Should we canonicalize $address?

    # Only request the resource once, even if there are multiple calls
    # while the request is still outstanding
    Future->wait_all(
        map {
            shared_resource(\($self->inflight_requests->{ $_ }))
            ->fetch( sub { $ua->http_get( $_ ) })
        } @{ $self->ip_range_urls }
    )->then(sub( @fetched ) {
        my $result = '';
        for my $item (@fetched) {
            my( $body, $headers) = $item->get;
            $result .= $body;
        };
        Future->done( $result )
    });
}

sub ip_ranges_text( $self, %options ) {
    my $res;

    $options{ ua } ||= $self->ua;
    $options{ ip_range_urls } ||= $self->ip_range_urls;

    my $r = $self->_ip_ranges;
    if( $r ) {
        $res = Future->done( $r )

    } else {
        $res = $self->retrieve_ips(
            $options{ aws_ip_range_url },
            $options{ ua }
        )->then( sub {
            my( $body, $headers ) = @_;
            my $list = [split /\s*\n/, $body];
            Future->done( $list )
        });
    };

    $res
}

sub parse_ip_ranges( $self, $list ) {
    my @ip_ranges;
    for my $e (@{ $list }) {
        my $entry = {
            provider => 'cloudflare',
            range => NetAddr::IP->new( $e ),
        };

        push @ip_ranges, $entry;
    };

    $self->_ip_ranges( \@ip_ranges );
    return Future->done( $self->_ip_ranges() );
}

sub ip_ranges( $self, %options ) {
    my $res;

    my $r = $self->_ip_ranges;
    if( $r ) {
        $res = Future->done( $r )

    } else {
        $res = $self->ip_ranges_text(
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

1;

=head1 SEE ALSO

L<https://www.cloudflare.com/ips-v4>

L<https://www.cloudflare.com/ips-v6>

=cut