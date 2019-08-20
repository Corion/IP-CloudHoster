package Future::SharedResource;
use strict;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use Exporter 'import';
our @EXPORT_OK = qw(&shared_resource &make_shared_resource);

our $VERSION = '0.01';

=head1 NAME

Future::SharedResource - satisfy multiple requests for a resource as one

=head1 SYNOPSIS

    my $url = 'https://ip-ranges.amazonaws.com/ip-ranges.json';
    my $res = shared_resource( \$requests{ $url } )->fetch( sub {
        $ua->request($url)
    })->then( sub {
        # ...
    });

=head1 THUNDERING HERD

The following code demonstrates the Thundering Herd effect, we can have multiple
futures request the same data even if the data is cached after the first
successful response:

    my $req = $ua->request('https://ip-ranges.amazonaws.com/ip-ranges.json')
    ->then(sub {
        # ...
    });

The solution to prevent the Thundering Herd is to accumulate all requests to the
URL so that they will go through one Future:

    my $url = 'https://ip-ranges.amazonaws.com/ip-ranges.json';
    my $res = shared_resource( \$requests{ $url } )->fetch( sub {
        $ua->request($url)
    })->then( sub {
        # ...
    });

=head1 EXPORTED FUNCTIONS

=head2 C<< shared_resource >>

    my $res = shared_resource( \$resources{ $key } )->fetch( sub {
        # fetch the resource
    })->then( sub {
        # handle the result
    })

This function call ensures that only one request to the shared resource
identified by C<< \$resources{ $key } >> is active at the same time. All
other requests to the same resource get fulfilled together when the
request for the first resource completes.

This prevents making multiple requests for the same cached resource just
after the resource cache time has expired ("Thundering Herd").

The subroutine passed to the C<< ->fetch >> method must return a future.
The subroutine itself must not request the same shared resource again before
it returns.

The reference passed to the function is used by C<< shared_resource >>
to recognize requests for a common resource. For example for HTTP requests,
you could have a hash C<< %requested >> to indicate the requests in flight.

The values of the reference are private to C<< shared_resource >>.
The module guarantees that after all requests launching for the same resource
have finished, the value of the reference will be set to undef.

This allows keeping track of the number of requests in flight by counting
the references that point to defined values.

=cut

sub shared_resource {
    Future::SharedResource::Object->new( @_ )
}

=head2 C<< fetch_shared_resource >>

    my $f = fetch_shared_resource( \$singleton,
        sub {
            # fetch the resource
        }
    )->then(sub {
    })

This function is functionally the same as C< shared_resource >, but it doesn't
use fancy object syntax.

=cut

# This is basically a Future::Mutex with the tiny difference that things that
# come in while the "running" Future is not complete will share the result of
# that Future instead of getting run afterwards.

sub fetch_shared_resource( $singleton_ref, $fetch ) {
    my $res;
    my $handler = $$singleton_ref;
    if( $handler ) {
        $res = $handler->transform();
    } else {
        ${$singleton_ref} = $fetch->();

        # Maybe we should short-circuit here in the case where $$singleton_ref
        # already ->is_ready.

        $res = ${$singleton_ref}->transform();

        # We want to clean up once our fetch-future is ready
        # This might destroy reference loops too early :-/
        ${$singleton_ref}->on_ready(sub {
            undef ${$singleton_ref};
        });
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

our $VERSION = '0.01';

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

=head1 SEE ALSO

L<Future::Mutex> - for serial access instead of shared access

=cut
