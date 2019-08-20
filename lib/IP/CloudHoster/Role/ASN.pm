package IP::CloudHoster::Role::ASN;
use strict;
use Moo::Role;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use IP::CloudHoster::Info;

use Future;
use Future::SharedResource 'shared_resource';

our $VERSION = '0.01';

has 'ip_range' => (
    is => 'lazy',
    default => sub { require IP::ASN; IP::ASN->new(); },
);

has '_ip_ranges' => (
    is => 'rw',
);

requires 'asn';
requires 'provider';

sub ip_ranges( $self, %options ) {
    if( $self->{_ip_ranges}) {
        return Future->done( $self->{_ip_ranges} );
    };

    shared_resource( \${ $self->{_ip_ranges}} )->fetch( sub {
        $self->ip_range()->get_range( asn => $self->asn, %options )
    })->on_done(sub {
        $self->{_ip_ranges} = $_[0];
        Future->done( @_ );
    });
}

sub identify( $self, $ip, %options ) {
    $ip = NetAddr::IP->new( $ip );
    $self->ip_ranges( %options )->then(sub {
        my( $ip_ranges ) = @_;

        for my $prefix (@$ip_ranges) {
            my $p = NetAddr::IP->new( $prefix );
            if( $ip->within( $p )) {
                return Future->done(IP::CloudHoster::Info->new({
                    provider => $self->provider,
                    range => $prefix,
                    ip => $ip,
                }))
            };
        };

        return Future->fail( "notfound", "ip" => $ip );
    });
}

1;

=head1 SEE ALSO

L<http://www.team-cymru.org/IP-ASN-mapping.html> - this would be a lookup using DNS

This database is not yet what we use to determine the ASN of an IP address. This
might be better (or worse) than using L<Net::IRR>

=cut
