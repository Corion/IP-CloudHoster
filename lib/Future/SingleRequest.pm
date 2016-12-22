package Future::SharedResource;
use strict;
use Future;
use parent 'Future';

=head1 SYNOPSIS

    # Thundering herd
    my $req = ua->request('https://ip-ranges.amazonaws.com/ip-ranges.json')
    ->then(sub {
    } );


    # No thundering herd
    my $url = 'https://ip-ranges.amazonaws.com/ip-ranges.json';
    my $req =
        shared_resource( \$requests{ $url } => sub { ua->request($url) })
    ->then(sub {
    } );

    shared_resource( \$requests{ $url } )->fetch( sub {
        ua->request($url))
    })->then( sub {
    })


    shared_resource( \$requests{ $url } )->fetch( sub {
        ua->request($url))
    })->then( sub {
    })

=cut

sub shared_resource {
    my( $singleton_ref, $fetch ) = @_;

    my $res;
    if( $singleton_ref ) {
        $res = Future->transform( $$singleton_ref )

    } else {

        $$singleton_ref = Future->wrap( $fetch->() );
        $res = Future->transform( $$singleton_ref,
            done => sub{ undef $$singleton_ref }
        );
    };

    $res
}


sub fetch {
    my( $self, $fetch ) = @_;

    resource_request(
        $self->{_singleton},
        $fetch
    );
}

1;