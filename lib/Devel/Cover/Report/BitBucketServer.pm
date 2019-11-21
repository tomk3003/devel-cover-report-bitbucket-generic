package Devel::Cover::Report::BitBucketServer;

use strict;
use warnings;
use Path::Tiny qw(path);
use JSON::MaybeXS qw(encode_json);

our $VERSION = '0.1';

sub report {
    my ( $pkg, $db, $options ) = @_;

    my $cover = $db->cover;

    my @cfiles;
    for my $file ( @{ $options->{file} } ) {
        my $f  = $cover->file($file);
        my $st = $f->statement;
        my $br = $f->branch;

        my %fdata = ( path => $file, );

        my %lines = ( co => [], uc => [] );
        for my $lnr ( sort { $a <=> $b } $st->items ) {
            my $sinfo = $st->location($lnr);
            if ($sinfo) {
                my $covered = 0;
                for my $o (@$sinfo) {
                    my $ocov = $o->covered     // 0;
                    my $ounc = $o->uncoverable // 0;
                    $covered |= $ocov || $ounc;
                }
                my $to = $covered > 0 ? 'co' : 'uc';
                push @{ $lines{$to} }, $lnr;
            }
        }
        my $co_str = @{ $lines{co} } ? 'C:' . join( ',', @{ $lines{co} } ) : '';
        my $uc_str = @{ $lines{uc} } ? 'U:' . join( ',', @{ $lines{uc} } ) : '';
        $fdata{coverage} = "$co_str;$uc_str";
        push @cfiles, \%fdata;
    }

    my $json = encode_json( { files => \@cfiles } );
    path('cover_db/bitbucket_server.json')->spew($json);
}


1;

__END__

=pod

=head1 NAME

Devel::Cover::Report::BitBucketServer - BitBucket Server backend for Devel::Cover

=head1 SYNOPSIS

    > cover -report BitBucketServer

=head1 DESCRIPTION

This module generates an JSON file suitable for import into Bitbucket Server from an existing
Devel::Cover database.

It is designed to be called from the C<cover> program distributed with L<Devel::Cover>.

The output file will be C<cover_db/bitbucket_server.json>.

To upload the file to BitBucket Server you have to upload it via the Bitbucket Server REST API provided by the plugin
B<Code Coverage for Bitbucket Server>. Please see
L<https://bitbucket.org/atlassian/bitbucket-code-coverage/src/master/code-coverage-plugin/>
on how to do that.

B<This will not work for Bitbucket Cloud.>

=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

=cut
