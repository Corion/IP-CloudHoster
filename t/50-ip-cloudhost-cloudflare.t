#!perl -w
use strict;
use Test::More tests => 4;
use Data::Dumper;

use IP::CloudHoster;

my $ch = IP::CloudHoster->new();

my $ip = join ".", unpack 'C4', gethostbyname( 'cloudflare.com' );

ok $ip, "We found an IP for 'cloudflare.com'";
my $info = $ch->identify( $ip )->get;

isa_ok $info, 'IP::CloudHoster::Info', "We found information on $ip";

is $info->{provider}, 'cloudflare', "cloudflare.com is hosted by Cloudflare";

$ip = '127.0.0.1';

$info = $ch->identify( $ip )->get;

is $info, undef, "localhost is not a cloud provider";
