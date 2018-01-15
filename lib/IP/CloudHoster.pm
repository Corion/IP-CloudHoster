package IP::CloudHoster;
use strict;
use Module::Pluggable
    instantiate => 'new',
    search_path => 'IP::CloudHoster',
    sub_name => 'class_plugins',
    except => [qw[IP::CloudHoster::Role::ASN IP::CloudHoster::Info]];
use Moo;
use Future;

our $VERSION = '0.01';

=head1 NAME

IP::CloudHoster -  Determine VPSes and cloud hosting machines via their IP address

=head1 SYNOPSIS

  my $ipranges = IP::CloudHoster->new();
  if( my $info = $id->identify( $ip )->get()) {
      print "$ip belongs to " . $info->provider;
  } else {
      print "$ip doesn't belong to a known cloud hoster";
  }

=cut

has plugins => (
    is => 'ro',
    default => sub { [ __PACKAGE__->class_plugins ] },
);

=head2 C<< ->identify( $ip )->get >>

  my $info = $id->identify( $ip )->get;
  print "$ip belongs to " . $info->provider;

=cut

sub identify {
    my( $self, $ip, %options ) = @_;

    # we'll return the first future that responds favourably
    my $res = Future->new();
    my $f = Future->needs_any(
        map {
            $_->identify( $ip, %options )
        } @{ $self->plugins }
    )->on_fail(sub {
        $res->done()
    })->on_done($res);
    return $res
}

=head1 SOURCES

=head2 Amazon AWS

L<https://ip-ranges.amazonaws.com/ip-ranges.json>

L<https://cloud.google.com/compute/docs/faq#ipranges> (DNS)

=head2 Cloudflare

=head2 Microsoft Azure

L<https://www.microsoft.com/en-us/download/details.aspx?id=41653>

=cut

1