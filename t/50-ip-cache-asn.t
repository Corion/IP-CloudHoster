#!perl -w
use strict;
use Test::More tests => 1;
use Data::Dumper;

use IP::CloudHoster;
use IP::ASN;

my %fetched;
{
my $org = \&IP::ASN::get_range;
no warnings 'redefine';
local *IP::ASN::get_range = sub {
    my( $self, %options ) = @_;
    $fetched{ $options{ asn }}++;
    goto &$org;
};
}

my $ch = IP::CloudHoster->new();

my @hosts = (
    '127.0.0.1',
	'howtogeek.com',
	'datenzoo.de',
	'netflix.com',
);

for my $h (@hosts) {
    my $info = $ch->identify( $h )->get;
};

my @double_fetched = grep {
    $fetched{ $_ } != 1
} sort keys %fetched;

is 0+@double_fetched, 0, "No ASN was fetched more than once"
    or diag Dumper \@double_fetched;
