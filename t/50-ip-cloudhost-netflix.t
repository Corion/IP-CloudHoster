#!perl -w
use strict;
use Test::More tests => 4;
use Data::Dumper;

use IP::CloudHoster;

my $ch = IP::CloudHoster->new();

my $ip = join ".", unpack 'C4', gethostbyname( 'netflix.com' );

ok $ip, "We found an IP for 'netflix.com'";
my $info = $ch->identify( $ip )->get;

ok $info, "We found information on $ip";

is $info->{provider}, 'amazon', "Netflix.com is hosted by Amazon";

my $ip = '127.0.0.1';

$info = $ch->identify( $ip )->get;

is $info, undef, "localhost is not a cloud provider";
