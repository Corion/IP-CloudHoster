package IP::CloudHoster::GoogleBot;
use strict;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use Future;
use AnyEvent::Future;
use AnyEvent::DNS;
use Future::SharedResource 'shared_resource';

our $VERSION = '0.01';

# This is to prevent a thundering herd when multiple requests are made
has 'inflight_requests' => (
    is => 'ro',
    default => sub { {} },
);

sub reverse_lookup( $self, $address ) {
    # Should we canonicalize $address?

    # Only request the resource once, even if there are multiple calls
    # while the request is still outstanding
    shared_resource(\($self->inflight_requests->{ $address }))
    ->fetch( sub {
        my $f = AnyEvent::Future->new;
        #warn "Verifying $address";
        AnyEvent::DNS::reverse_verify( $address, sub {
            if( $_[0] ) {
                $f->done(@_)
            } else {
                $f->fail("Reverse DNS for $address not found", "reverse_dns" => $address)
            }
        });
        return $f
    })
    ->then( sub( @hostnames ) {
        #warn "Checking $_" for @hostnames;
        my @ok = grep { /(google\.com|googlebot\.com)$/i } @hostnames;

        if( 0+@ok ) {
            return Future->done( @ok )
        } else {
            return Future->fail( "No Google domain name", "reverse_dns" => $address );
        }
    })
}

sub identify( $self, $ip, %options ) {
    $self->reverse_lookup( $ip )->then(sub( @hostnames ) {
        return Future->done(IP::CloudHoster::Info->new({
            region => undef,
            provider => 'googlebot',
            range => NetAddr::IP->new( $ip ),
        }))
    });
}

1
