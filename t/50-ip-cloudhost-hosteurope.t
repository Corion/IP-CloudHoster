#!perl -w
use strict;
use Test::More tests => 4;
use Data::Dumper;

use IP::CloudHoster;

use NetAddr::IP;
my $dz = NetAddr::IP->new( '83.169.23.242/32' );
warn $dz->within(NetAddr::IP->new('83.169.16.0/21'));

my $ch = IP::CloudHoster->new();

my $ip = join ".", unpack 'C4', gethostbyname( 'datenzoo.de' );

ok $ip, "We found an IP for 'datenzoo.de'";
my $info = $ch->identify( $ip )->get;

isa_ok $info, 'IP::CloudHoster::Info', "We found information on $ip";

is $info->{provider}, 'hosteurope', "datenzoo.de is hosted by hosteurope";

$ip = '127.0.0.1';

$info = $ch->identify( $ip )->get;

is $info, undef, "localhost is not a cloud provider";
