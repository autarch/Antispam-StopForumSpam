package Antispam::StopForumSpam::CLI::UpdateDatabase;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

use Antispam::StopForumSpam::BerkeleyDB;
use Antispam::StopForumSpam::Downloader;
use Antispam::StopForumSpam::Types
    qw( Bool DownloadDays DownloadType File Str );

use Moose;

with 'MooseX::Getopt::Dashes';

has type => (
    is            => 'ro',
    isa           => DownloadType,
    required      => 1,
    documentation => 'The type of file to download - email, ip, or username',
);

has days => (
    is       => 'ro',
    isa      => DownloadDays,
    required => 1,
    documentation =>
        'The number of days worth of data to download - 1, 7, 30, 90, 180, 365',
);

has database => (
    is            => 'ro',
    isa           => File,
    coerce        => 1,
    required      => 1,
    documentation => 'The database file to update',
);

has verbose => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has uri_base => (
    is        => 'ro',
    isa       => Str,
    default   => 'http://www.stopforumspam.com/downloads/',
    predicate => '_has_uri_base',
    documentation =>
        'The base path for downloads - defaults to download from stopforumspam.com',
);

sub run {
    my $self = shift;

    $self->_maybe_say('Downloading new file');

    my $dl = Antispam::StopForumSpam::Downloader->new(
        $self->_has_uri_base()
        ? ( uri_base => $self->uri_base() )
        : ()
    );

    my $file = $dl->download_and_save(
        type => $self->type(),
        days => $self->days(),
    );

    $self->_maybe_say("Downloaded file and saved it at $file");

    $self->_maybe_say( "Updating database at " . $self->database() );

    Antispam::StopForumSpam::BerkeleyDB->build(
        file     => $file,
        database => $self->database(),
    );

    $self->_maybe_say('Completed updating database');
}

sub _maybe_say {
    my $self = shift;
    my $msg  = shift;

    return unless $self->verbose();

    print "  $msg\n";
}

1;
