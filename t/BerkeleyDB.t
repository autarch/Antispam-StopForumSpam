use strict;
use warnings;

use BerkeleyDB::Hash;
use File::Temp qw( tempdir );
use Path::Class qw( dir file );

use Test::More 0.88;

use Antispam::StopForumSpam::BerkeleyDB;

my $dir = dir( tempdir( CLEANUP => 1 ) );

my $file = $dir->file('listed_email_7.db');

{
    Antispam::StopForumSpam::BerkeleyDB->build(
        database => $file,
        file     => file( 't', 'data', 'listed_email_7.zip' ),
    );

    ok(
        -f $file,
        'build creates a new Berkeley DB file'
    );

    my $db = BerkeleyDB::Hash->new( -Filename => $file );

    for my $email (qw( foo@example.com bar@example.com )) {
        my $val;
        $db->db_get( $email, $val );

        ok(
            $val,
            "Berkeley DB file contains $email"
        );
    }

    {
        my $val;
        $db->db_get( 'autarch@urth.org', $val );

        ok(
            !$val,
            'Berkeley DB file does not contain autarch@urth.org'
        );
    }
}

{
    my $sfsdb = Antispam::StopForumSpam::BerkeleyDB->new(
        database => $file,
        name     => 'listed email 7',
    );

    for my $email (qw( foo@example.com bar@example.com )) {
        ok(
            $sfsdb->contains_value($email),
            "Berkeley DB file contains $email (contains_value method)"
        );
    }

    ok(
        !$sfsdb->contains_value('autarch@urth.org'),
        'Berkeley DB file does not contain autarch@urth.org (contains_value method)'
    );
}

done_testing();
