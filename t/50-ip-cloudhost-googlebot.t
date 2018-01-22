#!perl -w
use strict;
use Test::More tests => 3;
use Data::Dumper;

use IP::CloudHoster;
use NetAddr::IP;

use AnyEvent::DNS;

my $googlebot = '66.249.66.1';

my $ch = IP::CloudHoster->new();

my $info = $ch->identify( $googlebot )->get;

isa_ok $info, 'IP::CloudHoster::Info', "We found information on $googlebot";

is $info->{provider}, 'googlebot', "$googlebot is googlebot";

my $ip = '127.0.0.1';

$info = $ch->identify( $ip )->get;

is $info, undef, "localhost is not a cloud provider";
