package IP::ASN;
use strict;
use Carp 'croak';
use Future;
use Moo 2;
no warnings 'experimental';
use Filter::signatures;
use feature 'signatures';
use Net::IRR;

our $VERSION = '0.01';

=head1 NAME

IP::ASN - Get the IP ranges associated with an autonomous system number (ASN)

=head1 SYNOPSIS

  my $ranges = IP::ASN->new();
  my $facebook = 'as32934';
  $ranges->get_range( $facebook )->then(sub {
      my (@ranges) = @_;
      # '204.15.20.0/22', ...
      ...
  })

=cut

sub get_range($class, %options) {
    croak "Need an ASN to query"
        unless $options{ asn };
    $options{ hostname } ||= 'whois.radb.net';
    $options{ irr } ||= Net::IRR->connect( host => $options{ hostname })
        or die "can't connect to $options{ hostname }: $?"; # let's hope that $? is still valid
    my $asn = $options{ asn };
    my @results = $options{ irr }->get_routes_by_origin($asn);
    push @results, $options{ irr }->get_ipv6_routes_by_origin($asn);

    Future->done(@results)
}

=head1 SEE ALSO

L<http://www.team-cymru.org/IP-ASN-mapping.html> - this would be a lookup using DNS

=cut

package CloudHoster::ASN;

1;