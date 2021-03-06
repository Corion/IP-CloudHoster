package IP::ASN;
use strict;
use Carp 'croak';
use Future;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Net::IRR;

our $VERSION = '0.01';

=head1 NAME

IP::ASN - Get the IP ranges associated with an autonomous system number (ASN)

=head1 SYNOPSIS

  my $ranges = IP::ASN->new();
  my $facebook = 'as32934';
  $ranges->get_range( $facebook )->then(sub {
      my ($ranges) = @_;
      # $ranges->[0] eq '204.15.20.0/22', ...
      print "$_\n" for @$ranges
  })

=head1 FUNCTIONS

=head2 C<< get_range >>

  get_range(asn => 'as32934')->then(sub {
      my( $ranges ) = @_;

      my @entries;
      for my $mask (@$ranges) {
          my $entry = {
              provider => 'facebook',
              range => NetAddr::IP->new( $mask ),
          };
          push @entries, $entry;
      };
      Future->done( @entries )
  })

The function returns a Future that returns all prefixes associated with the
ASN as found via L<Net::IRR>.

You should likely rate-limit access to the C<< get_range >> function.

=cut

sub get_range($class, %options) {
    croak "Need an ASN to query"
        unless $options{ asn };
    $options{ hostname } ||= 'whois.radb.net';
    $options{ irr } ||= Net::IRR->connect( host => $options{ hostname })
        or die "can't connect to $options{ hostname }: $?"; # let's hope that $? is still valid
    my $asns = $options{ asn };
    if( ! ref $asns or ref $asns ne 'ARRAY') {
        $asns = [$asns]
    };
    my @results;
    for my $asn (@$asns) {
        push @results, $options{ irr }->get_routes_by_origin($asn);
        push @results, $options{ irr }->get_ipv6_routes_by_origin($asn);
    };

    Future->done(\@results)
}

1;

=head1 SEE ALSO

L<http://www.team-cymru.org/IP-ASN-mapping.html> - this would be a lookup using DNS

L<Net::IRR>

=cut

1;
