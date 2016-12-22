package IP::CloudHoster::AWS;
use strict;
use Moo 2;
use Future;
use Net::Netmask;
use JSON::XS 'decode_json';
use Future::SharedResource 'shared_resource';

has 'aws_ip_range_url' => (
    is => 'rw',
    default => 'https://ip-ranges.amazonaws.com/ip-ranges.json',
);

has 'ua' => (
    is => 'lazy',
    default => sub {
        require HTTP::Future;
        HTTP::Future->new(),
    },
);

# This is to prevent a thundering herd when multiple requests are made
has '_inflight_request' => (
    is => 'rw',
);

has '_aws_ip_ranges' => (
    is => 'rw',
);

# Also, can we turn the UA into a queueing resource with a similar
# approach?

my %requests;
sub retrieve_aws_ips {
    my( $self, $address, $ua ) = @_;
    
    # Only request the resource once, even if there are multiple calls
    # while the request is still outstanding
    shared_resource(\$requests{ $address })
    ->fetch( sub { $ua->http_get( $address ) })
}

sub ip_ranges_json {
    my( $self, %options ) = @_;
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
            $json
        });
    };

    $res
}

sub parse_ip_ranges {
    my( $self, $json ) = @_;
    
    my @ip_ranges;
    for my $e (@{ $json->{prefixes} }) {
        my $entry = {
            %$e,
            provider => 'amazon',
            range => Net::Netmask->new( $e->{ ip_prefix } ),
        };
        
        push @ip_ranges, $entry;
    };
    
    $self->_aws_ip_ranges( $ip_ranges );
    return $self->_aws_ip_ranges();
}

sub ip_ranges {
    my( $self, %options ) = @_;
    my $res;
    
    my $r = $self->_aws_ip_ranges;
    if( $r ) {
        $res = Future->done( $r )

    } else {
        $res = $self->ip_ranges_json(
            %options
        )->then( sub {
            my( $body, $headers ) = @_;
            my $json = decode_json( $body );
            $self->parse_ip_ranges( $json );
        });
    };

    $res
}

sub identify {
    my( $self, $ip, %options ) = @_;
    
    $self->ip_ranges( %options )->then(sub {
        my( $ip_ranges ) = @_;
        
        for my $prefix (@$ip_ranges) {
            if( $prefix->{range}->match( $ip ) {
                return $prefix
            };
        };
        
        return()
    });
}

1