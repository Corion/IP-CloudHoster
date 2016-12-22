#!perl -w
use strict;
use Test::More tests => 6;

use Future::SharedResource 'shared_resource';
use AnyEvent::Future;
use Data::Dumper;

my $fetched_times;
sub fetch_info {
    my( $result ) = @_;
    $fetched_times++;
    
    my $f = AnyEvent::Future->new_delay( after => 5 )
    ->then( sub {
        Future->done( $result )
    });
};

my $started = time;
my $url;
my @requests = map {
    shared_resource(\$url)
    ->fetch(sub {
        fetch_info('the data')
    });
} 1..10;

my $done = Future->needs_all( @requests );
my @data = $done->get;

is $fetched_times, 1, "We only issued one request";
my $taken = time-$started;
cmp_ok $taken, '<', 10, "The requests all completed in under 10 seconds";

is_deeply \@data, [('the data') x 10], "All futures received the data"
    or diag Dumper \@data;

# Now also check that a new request is issued after all requests have finished:
$started = time;
$fetched_times = 0;
@requests = map {
    shared_resource(\$url)
    ->fetch(sub {
        fetch_info('more data')
    });
} 1..3;

$done = Future->needs_all( @requests );
@data = $done->get;

is $fetched_times, 1, "We only issued one request";
$taken = time-$started;
cmp_ok $taken, '<', 10, "The requests all completed in under 10 seconds";

is_deeply \@data, [('more data') x 3], "All futures received the data"
    or diag Dumper \@data;
