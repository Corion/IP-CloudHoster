#!perl -w
use strict;
use Test::More tests => 12;

use Future::SharedResource 'shared_resource';
use AnyEvent::Future;
use Data::Dumper;

my %fetched_times;
sub fetch_info {
    my( $url, $result ) = @_;
    $fetched_times{ $url }++;
    
    my $f = AnyEvent::Future->new_delay( after => 5 )
    ->then( sub {
        Future->done( $result )
    });
};

my $started = time;
my %url;
my @requests = map {
    my $url = $_;
    shared_resource(\$url{$url})
    ->fetch(sub {
        fetch_info($url, 'the data ' . $url)
    });
} (1..10) x 4;

my $done = Future->needs_all( @requests );
my @data = $done->get;

my $taken = time-$started;
for my $url (1..10) {
    is $fetched_times{$url}, 1, "We only issued one request for url $url";
};
cmp_ok $taken, '<', 10, "The requests all completed in under 10 seconds";

is_deeply [sort @data], [sort map { ('the data ' . $_) x 4 } 1..10], "All futures received the data"
    or diag Dumper \@data;

