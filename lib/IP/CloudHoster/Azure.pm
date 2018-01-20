package IP::CloudHoster::Azure;
use strict;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use Future;
use NetAddr::IP;
use IP::CloudHoster::Info;
use Future::SharedResource 'shared_resource';

our $VERSION = '0.01';
our $ip_range_url = 'http://www.microsoft.com/EN-US/DOWNLOAD/confirmation.aspx?id=41653';
our $xml_base_url = 'http://download.microsoft.com/download/0/1/8/018E208D-54F8-44CD-AA26-CD7BC9524A8C/';

has 'ip_range_url' => (
    is => 'rw',
    default => $ip_range_url,
);

has 'xml_base_url' => (
    is => 'rw',
    default => $xml_base_url,
);

has 'ua' => (
    is => 'lazy',
    default => sub {
        require Future::HTTP;
        return Future::HTTP->new(),
    },
);

has 'libxml' => (
    is => 'lazy',
    default => sub {
        require XML::LibXML;
        return XML::LibXML->new();
    },
);

# This is to prevent a thundering herd when multiple requests are made
has 'inflight_requests' => (
    is => 'ro',
    default => sub { {} },
);

has '_ip_ranges' => (
    is => 'rw',
);

# Also, can we turn the UA into a queueing resource with a similar
# approach?

sub retrieve_azure_ips( $self, $address, $ua ) {
    # Should we canonicalize $address?

    # Only request the resource once, even if there are multiple calls
    # while the request is still outstanding
    shared_resource(\($self->inflight_requests->{ $address }))
    ->fetch( sub { $ua->http_get( $address ) })
    ->then( sub( $body, $headers ) {
        $body =~ /(PublicIps\w+.xml)/i
            or die "Couldn't find the filename in the page";
        my $xml_url = $self->xml_base_url.$1;
        $ua->http_get( $xml_url )
    })
}



#<AzurePublicIpAddresses xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
#<Region Name="australiaeast">
#<IpRange Subnet="13.70.64.0/18"/>
#<IpRange Subnet="13.72.224.0/19"/>
#...
#</Region>

sub ip_ranges_xml( $self, %options ) {
    my $res;

    $options{ ua } ||= $self->ua;
    $options{ ip_range_url } ||= $self->ip_range_url;

    my $r = $self->_ip_ranges;
    if( $r ) {
        $res = Future->done( $r )

    } else {
        $res = $self->retrieve_azure_ips(
            $options{ ip_range_url },
            $options{ ua }
        )->then( sub( $body, $headers ) {
            $self->parse_ip_xml( $body )
        });
    };

    $res
}

sub parse_ip_xml( $self, $xml ) {
    my $parser = $self->libxml;
    my $doc = $parser->load_xml( string => $xml );
    #warn $xml;
    my $data = $doc->findnodes('//IpRange[@Subnet]');
    return Future->done( [$data->get_nodelist] );
}

sub parse_ip_ranges( $self, $data ) {
    my @ip_ranges;
    for my $e (@{ $data }) {
        my $entry = IP::CloudHoster::Info->new({
            region => $e->parentNode->getAttribute('Name'),
            provider => 'azure',
            range => NetAddr::IP->new( $e->getAttribute('Subnet') ),
        });

        push @ip_ranges, $entry;
    };

    $self->_ip_ranges( \@ip_ranges );
    return Future->done( $self->_ip_ranges() );
}

sub ip_ranges( $self, %options ) {
    my $res;

    if( my $r = $self->_ip_ranges ) {
        $res = Future->done( $r )

    } else {
        $res = $self->ip_ranges_xml(
            %options
        )->then( sub( $data ) {
            $self->parse_ip_ranges( $data );
        });
    };

    $res
}

sub identify( $self, $ip, %options ) {
    $ip = NetAddr::IP->new( $ip );
    $self->ip_ranges( %options )->then(sub {
        my( $ip_ranges ) = @_;

        for my $prefix (@$ip_ranges) {
            if( $ip->within( $prefix->{range})) {
                return Future->done( $prefix )
            };
        };

        return Future->fail()
    });
}

1