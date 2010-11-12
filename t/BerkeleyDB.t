use strict;
use warnings;

use Antispam::StopForumSpam::BerkeleyDB;
use File::Temp qw( tempdir );
use Path::Class qw( dir file );

use Test::More 0.88;

my $dir = dir( tempdir( CLEANUP => 1 ) );

my $file = $dir->file('listed_email_7.db');

Antispam::StopForumSpam::BerkeleyDB->build(
    database => $file,
    file     => file( 't', 'data', 'listed_email_7.zip' ),
);

{
    my $sfsdb = Antispam::StopForumSpam::BerkeleyDB->new(
        database => $file,
        name     => 'listed email 7',
    );

    for my $email (qw( foo@example.com bar@example.com )) {
        ok(
            $sfsdb->match_value($email),
            "Berkeley DB file contains $email (match_value method)"
        );
    }

    ok(
        !$sfsdb->match_value('autarch@urth.org'),
        'Berkeley DB file does not contain autarch@urth.org (match_value method)'
    );
}

done_testing();
