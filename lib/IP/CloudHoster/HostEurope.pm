package IP::CloudHoster::HostEurope;
use Moo 2;

use constant 'asn' => [
    'AS8972',  # DE
    'AS20773', # DE
    'AS20738', # UK
    'AS35329', # DE
];
use constant 'provider' => 'hosteurope';

with 'IP::CloudHoster::Role::ASN';

our $VERSION = '0.01';

1;
