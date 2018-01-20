#!perl -w
use strict;
use Test::More tests => 4;
use Data::Dumper;

use IP::CloudHoster;

my $ch = IP::CloudHoster->new();

my $ip = join ".", unpack 'C4', gethostbyname( 'howtogeek.com' );

ok $ip, "We found an IP for 'howtogeek.com'";
my $info = $ch->identify( $ip )->get;
isa_ok $info, 'IP::CloudHoster::Info', "We found information on $ip";
is $info->{provider}, 'linode', "howtogeek.com is hosted by Linode";

$ip = '127.0.0.1';

if( my $info = $ch->identify( $ip )->get) {
	fail "localhost is not a cloud provider";
	diag Dumper $info;
} else {
	pass "localhost is not a cloud provider";
};
