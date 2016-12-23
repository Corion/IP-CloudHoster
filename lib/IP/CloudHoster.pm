package IP::CloudHoster;
use strict;
use Module::Pluggable instantiate => 'new';
use Moo;
use Future;

has plugins => (
    is => 'ro',
    default => sub { [ $class->plugins ] },
);

=head2 C<< ->identify( $ip )->get >>

  my $info = $id->identify( $ip )->get;
  print "$ip belongs to " . $info->provider;

=cut

sub identify {
    my( $self, $ip, %options ) = @_;

    # we'll return the first future that responds favourably
    my $f = Future->needs_any(
        map {
            $_->identify( $ip, %options );
        } @{ $self->plugins }
    );
    return $f
}

=head1 SOURCES

    https://cloud.google.com/compute/docs/faq#ipranges (DNS)
    Cloudflare

Microsoft Azure

  https://www.microsoft.com/en-us/download/confirmation.aspx?id=41653

=cut

1