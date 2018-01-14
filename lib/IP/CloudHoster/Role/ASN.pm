package IP::CloudHoster::Role::ASN;
use strict;
use Moo::Role;
no warnings 'experimental';
use Filter::signatures;
use feature 'signatures';

use Future;

has 'ip_range' => (
    is => 'lazy',
    default => sub { require IP::ASN; IP::ASN->new(); },
);

requires 'asn';
requires 'provider';

sub ip_ranges( $self, %options ) {
    Future->wrap( $self->ip_range()->get_range( asn => $self->asn, %options ))
}

sub identify( $self, $ip, %options ) {
    $ip = NetAddr::IP->new( $ip );
    $self->ip_ranges( %options )->then(sub {
        my( $ip_ranges ) = @_;
        
        for my $prefix (@$ip_ranges) {
            my $p = NetAddr::IP->new( $prefix );
            if( $ip->within( $p )) {
                return Future->done({
                    provider => $self->provider,
                    range => $prefix,
                })
            };
        };

        return Future->fail;
    });
}

1;