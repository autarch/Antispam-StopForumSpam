package Antispam::StopForumSpam::Types::Internal;

use strict;
use warnings;

use Archive::Zip qw( AZ_OK );
use File::Temp qw( tempdir );
use Path::Class qw( dir file );

use MooseX::Types -declare => [
    qw(
        BerkeleyDB
        DownloadDays
        DownloadType
        SFSDatabase
        SFSTextFile
        SFSZipFile
        )
];

use MooseX::Types::Common::String qw( NonEmptyStr );
use MooseX::Types::Moose qw( Str );
use MooseX::Types::Path::Class qw( File );

my @days = ( 1, 7, 30, 90, 180, 365 );
enum DownloadDays, @days;

my @types = qw( ip email username );
enum DownloadType, @types;

my $valid_types_re = '(?:' . ( join '|', @types ) . ')';
my $valid_days_re  = '(?:' . ( join '|', @days ) . ')';

subtype SFSTextFile,
    as File,
    where { $_->basename() =~ /${valid_types_re}_${valid_days_re}\.txt/ },
    message { "$_ does not look like the name of a text file downloaded from stop forum spam" };

subtype SFSZipFile,
    as File,
    where { $_->basename() =~ /${valid_types_re}_${valid_days_re}\.zip/ },
    message { "$_ does not look like the name of a zip file downloaded from stop forum spam" };

coerce SFSTextFile,
    from NonEmptyStr,
    # We want to coerce the file again if it's a .zip file
    via { SFSTextFile()->coerce( file($_) ) };

coerce SFSZipFile,
    from NonEmptyStr,
    via { file($_) };

coerce SFSTextFile,
    from SFSZipFile,
    via { _unzip_sfs_file($_) };

role_type SFSDatabase, { role => 'Antispam::StopForumSpam::Role::Database' };

sub _unzip_sfs_file {
    my $zip = shift;
    my $arch = Archive::Zip->new( $zip->stringify() );

    my @members = $arch->members();

    die "Bad zip file - contains wrong members (@members)"
        unless @members == 1;

    my $dir = dir( tempdir( CLEANUP => 1 ) );

    my $extract_to = $dir->file( file( $members[0]->fileName() )->basename() );

    $arch->extractMember( $members[0], $extract_to->stringify() ) == AZ_OK
        or die "Cannot extract $members[0] from the zip file ($zip)";

    return $extract_to;
}

1;
