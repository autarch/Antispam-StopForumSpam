use strict;
use warnings;

use Test::More 0.88;

use Antispam::StopForumSpam::Types qw( SFSTextFile );
use Cwd qw( abs_path );
use Digest::MD5 qw( md5_base64 );
use File::Slurp qw( read_file );
use Path::Class qw( dir );

{
    my $data_dir = dir( abs_path('.') )->subdir( 't', 'data' );

    my $file = SFSTextFile()
        ->coerce( $data_dir->file('listed_email_7.zip')->stringify() );

    is(
        $file->basename(), 'listed_email_7.txt',
        'coerced zip file to expected text file'
    );

    is(
        md5_base64( read_file( $file->stringify() ) ),
        md5_base64(
            read_file( $data_dir->file('listed_email_7.txt')->stringify() )
        ),
        'coerced file has expected contents'
    );
}

done_testing();
