#!perl -w
use strict;
use IP::ASN;
use NetAddr::IP qw(:lower);

use Test::More tests => 4;

my $find = IP::ASN->new();

my $ip = join ".", unpack 'C4', gethostbyname( 'facebook.com' );

ok $ip, "We found an IP for 'facebook.com'";
my $ranges = $find->get_range(asn => 'as32934')->get;
ok $ranges, "We found IP range information on as32934 (facebook)";

$ip = NetAddr::IP->new($ip);

# Now scan the ranges in $info for the IP address of facebook:
my @facebook = grep {
    my $m = NetAddr::IP->new( $_ );
    $ip->within( $m )
} @$ranges;

ok 0+@facebook, "We find facebook.com in the list belonging to as32934";

$ip = NetAddr::IP->new('127.0.0.1');

# Now scan the ranges in $info for the IP address of facebook:
my @localhost = grep {
    my $m = NetAddr::IP->new( $_ );
    $ip->within( $m )
} @$ranges;

is 0+@localhost, 0, "127.0.0.1 is not in the list belonging to as32934";