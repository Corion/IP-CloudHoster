package IP::CloudHoster::Info;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

our $VERSION = '0.01';

=head1 NAME

IP::CloudHoster::Info - information about an IP address

=head1 SYNOPSIS

  my $ipranges = IP::CloudHoster->new();
  if( my $info = $id->identify( $ip )->get()) {
      print "$ip belongs to " . $info->provider;
  } else {
      print "$ip doesn't belong to a known cloud hoster";
  }

=head1 METHODS

=head2 C<< provider >>

The name of the provider

=cut

has 'provider' => (
    is => 'ro',
);

=head2 C<< region >>

The (provider-specific) name of the region, if available

=cut

has 'region' => (
    is => 'ro',
);

=head2 C<< range >>

L<NetAddr::IP> representing the range

=cut

has 'range' => (
    is => 'ro',
);

1;
