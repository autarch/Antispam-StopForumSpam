use strict;
use warnings;

use Antispam::StopForumSpam;
use Antispam::StopForumSpam::BerkeleyDB;
use File::Temp qw( tempdir );
use Path::Class qw( dir file );

use Test::Fatal;
use Test::More 0.88;

my $dir = dir( tempdir( CLEANUP => 1 ) );

$dir->subdir($_)->mkpath( 0, 0755 ) for qw( email ip username );

my %dbs;

for my $type (qw( email ip username )) {
    my $file = $dir->file( 'email', 'listed_' . $type . '_7.db' );

    Antispam::StopForumSpam::BerkeleyDB->build(
        database => $file,
        file     => file( 't', 'data', 'listed_' . $type . '_7.zip' ),
    );

    $dbs{$type} = Antispam::StopForumSpam::BerkeleyDB->new(
        database => $file,
        name     => $file->basename(),
    );
}

{
    like(
        exception { Antispam::StopForumSpam->new() },
        qr/\QYou must provide at least one database when constructing an Antispam::StopForumSpam object/,
        'cannot make a new SFS object with at least one database'
    );
}

{
    my $sfs = Antispam::StopForumSpam->new( email_database => $dbs{email} );

    ok(
        !$sfs->check_ip( ip => '127.0.0.1' ),
        'no result when checking an ip - no ip database for object'
    );

    my $res = $sfs->check_email( email => 'autarch@urth.org' );

    ok(
        defined $res,
        'got a result when email is not in the database file'
    );

    is(
        $res->score(), 0,
        'score is 0'
    );

    my @details = $res->details();
    is(
        scalar @details, 1,
        'got one detail string in the result'
    );

    like(
        $details[0],
        qr/\QThe email (autarch\E\@\Qurth.org) was not found in a StopForumSpam database (listed_email_7.db)/,
        'got expected result details'
    );

    $res = $sfs->check_email( email => 'foo@example.com' );

    ok(
        defined $res,
        'got a result when checking an email in the database'
    );

    is(
        $res->score(), 1,
        'score is 1'
    );

    @details = $res->details();
    is(
        scalar @details, 1,
        'got one detail string in the result'
    );

    like(
        $details[0],
        qr/\QThe email (foo\E\@\Qexample.com) was found in a StopForumSpam database (listed_email_7.db)/,
        'got expected result details'
    );
}

done_testing();
