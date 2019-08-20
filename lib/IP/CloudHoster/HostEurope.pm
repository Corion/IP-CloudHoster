package IP::CloudHoster::HostEurope;
use Moo 2;

use constant 'asn' => 'AS20773';
use constant 'provider' => 'hosteurope';

with 'IP::CloudHoster::Role::ASN';

our $VERSION = '0.01';

1;
