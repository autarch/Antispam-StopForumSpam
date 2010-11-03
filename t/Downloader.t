use strict;
use warnings;

use Test::More 0.88;

use Antispam::StopForumSpam::Downloader;
use Cwd qw( abs_path );
use Digest::MD5 qw( md5_base64 );
use File::Slurp qw( read_file );
use Path::Class qw( dir );
use URI;

my $data_dir = dir( abs_path('.') )->subdir( 't', 'data' );

my $dl = Antispam::StopForumSpam::Downloader->new(
    _uri_base => URI->new("file://$data_dir") );

# If we compare file contents directly then the output from a failure is
# several screens full of garbage.
is(
    md5_base64( $dl->download( type => 'email', days => 7 ) ),
    md5_base64(
        read_file( $data_dir->file('listed_email_7.zip')->stringify() )
    ),
    'download gets the expected file'
);

my $file = $dl->download_and_save( type => 'email', days => 7 );

is(
    md5_base64( read_file( $file->stringify() ) ),
    md5_base64(
        read_file( $data_dir->file('listed_email_7.zip')->stringify() )
    ),
    'download_and_save gets the expected file'
);

done_testing();
