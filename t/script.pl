#!perl -w
use strict;
use IP::ASN;

use Data::Dumper;
warn Dumper (
IP::ASN->get_range(
    asn => 'as32934',
)->get
);