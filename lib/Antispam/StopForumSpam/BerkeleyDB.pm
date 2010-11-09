package Antispam::StopForumSpam::BerkeleyDB;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

use Antispam::StopForumSpam::Types qw( BerkeleyDB File NonEmptyStr SFSTextFile );
use BerkeleyDB;

use Moose;
use MooseX::Params::Validate qw( validated_list );
use MooseX::StrictConstructor;

with 'Antispam::StopForumSpam::Role::Database';

has database => (
    is       => 'ro',
    isa      => File,
    coerce   => 1,
    required => 1,
);

has name => (
    is      => 'ro',
    isa     => NonEmptyStr,
    lazy    => 1,
    default => sub { $_[0]->database() },
);

has _db => (
    is       => 'ro',
    isa      => 'BerkeleyDB::Hash',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_db',
);

sub BUILD {
    my $self = shift;

    die "The database file must already exist"
        unless -f $self->database();
}

sub _build_db {
    my $self = shift;

    my $env = BerkeleyDB::Env->new(
        -Home  => $self->database()->dir(),
        -Flags => DB_INIT_CDB | DB_INIT_MPOOL,
    );

    return BerkeleyDB::Hash->new(
        -Filename => $self->database(),
        -Env      => $env,
    );
}

sub build {
    my $class = shift;
    my ( $file, $database ) = validated_list(
        \@_,
        file => {
            isa    => SFSTextFile,
            coerce => 1,
        },
        database => {
            isa    => File,
            coerce => 1,
        },
    );

    my $env = BerkeleyDB::Env->new(
        -Home  => $database->dir(),
        -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL,
    );

    my $db = BerkeleyDB::Hash->new(
        -Filename => $database,
        -Flags    => DB_CREATE,
        -Env      => $env,
    );

    my $lock = $db->cds_lock();

    $db->truncate( my $count );

    open my $fh, '<', $file;

    while (<$fh>) {
        chomp;
        $db->db_put( $_ => 1 );
    }

    $db->compact();

    $lock->cds_unlock();

    return;
}

sub contains_value {
    my $self = shift;
    my $key  = shift;

    my $value;
    $self->_db()->db_get( $key, $value );

    return $value;
}

__PACKAGE__->meta()->make_immutable();

1;
