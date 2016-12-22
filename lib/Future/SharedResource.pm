package Future::SharedResource;
use strict;
use Future;
use Exporter 'import';
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(&shared_resource &make_shared_resource);

=head1 SYNOPSIS

    # Thundering herd, we can have multiple futures request the same data:
    my $req = ua->request('https://ip-ranges.amazonaws.com/ip-ranges.json')
    ->then(sub {
    });


    # No thundering herd, all requests to the URL will go through one Future
    my $url = 'https://ip-ranges.amazonaws.com/ip-ranges.json';
    my $res = shared_resource( \$requests{ $url } )->fetch( sub {
        ua->request($url)
    })->then( sub {
        ...
    })

=head1 EXPORTED FUNCTIONS

=head2 C<< shared_resource >>

    my $res = shared_resource( \$resources{ $key } )->fetch( sub {
        ... # fetch the resource
    })->then( sub {
        ... # handle the result
    })

This function call ensures that only one request to the shared resource
identified by C<< \$resources{ $key } >> is active at the same time. All
other requests to the same resource get fulfilled together when the
request for the first resource completes.

This prevents making multiple requests for the same cached resource just
after the resource cache time has expired ("Thundering Herd").

=cut

sub shared_resource {
    Future::SharedResource::Object->new( @_ )
}

=head2 C<< fetch_shared_resource >>

    my $f = fetch_shared_resource( \$singleton,
        sub {
            ... # fetch the resource
        }
    )->then(sub {
    })

This function is functionally the same as C< shared_resource >, but it doesn't
use fancy object syntax.

=cut

sub fetch_shared_resource {
    my( $singleton_ref, $fetch ) = @_;

    my $res;
    if( $$singleton_ref ) {
        $res = ${$singleton_ref}->transform()

    } else {
        $$singleton_ref = Future->wrap( $fetch->() );
        $res = ${$singleton_ref}->transform(
            done => sub{ undef $$singleton_ref; @_ }
        );
    };

    $res
}

=head1 NOTE

On fulfillment, all Futures will receive the same data. If there are references
in the data, you must take care that all modifications to the shared data
are idempotent.

=cut

package Future::SharedResource::Object;
use strict;

sub new {
    my( $class, $singleton_ref ) = @_;
    my $self = bless {
        _singleton => $singleton_ref
    } => $class;
    $self
}

sub fetch {
    my( $self, $fetch ) = @_;

    Future::SharedResource::fetch_shared_resource(
        $self->{_singleton},
        $fetch
    );
}

1;