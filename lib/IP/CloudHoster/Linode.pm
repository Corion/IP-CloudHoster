package IP::CloudHoster::Linode;
use Moo 2;

use constant 'asn' => 'AS63949';
use constant 'provider' => 'linode';

with 'IP::CloudHoster::Role::ASN';

our $VERSION = '0.01';

1;
