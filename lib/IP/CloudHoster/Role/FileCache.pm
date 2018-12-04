package IP::CloudHoster::Role::FileCache;
use strict;
use Moo::Role;
use Path::Class 'file';
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

=head1 NAME

IP::CloudHoster::Role::FileCache - cache HTTP resources locally

=cut

our $cache_directory = $ENV{TEMP} || '/tmp';

has 'cache_directory' => (
    is => 'rw',
    default => $cache_directory,
);

has 'fresh_duration' => (
    is => 'rw',
    default => 48*3600, # two days before we re-fetch resources
);

has '_ip_ranges' => (
    is => 'rw',
);

requires 'filename';
requires 'fetch';

around 'fetch' => sub($orig, $self, @args) {

    my $fn = file( $self->cache_directory, $self->filename );
    if( time - (stat($fn))[9] < $self->fresh_duration) {
        return Future->done( $fn->slurp( iomode => ':raw' ), { Status => 200 } );
    };

    # We should add the if-modified-since headers, like ->mirror does.
    # or maybe just use $self->ua->mirror()
    $orig->( $self, @args )->then(sub( $body, $headers ) {
        # Update file if we can / want
        eval {
            $fn->spew( iomode => ':raw', $body );
        };
        return Future->done( $body, $headers )
    })
};

1;

=head1 SEE ALSO

L<http://www.team-cymru.org/IP-ASN-mapping.html> - this would be a lookup using DNS

This database is not yet what we use to determine the ASN of an IP address. This
might be better (or worse) than using L<Net::IRR>

=cut