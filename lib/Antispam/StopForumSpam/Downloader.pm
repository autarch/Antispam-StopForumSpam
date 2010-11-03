package Antispam::StopForumSpam::Downloader;

use strict;
use warnings;
use namespace::autoclean;

use Antispam::StopForumSpam::Types qw( DownloadDays DownloadType Str );
use File::Temp qw( tempdir );
use HTTP::Request;
use LWP::UserAgent;
use Path::Class qw( dir );
use URI;

use Moose;
use MooseX::Params::Validate qw( validated_list );
use MooseX::StrictConstructor;

has _ua => (
    is       => 'ro',
    isa      => 'LWP::UserAgent',
    init_arg => undef,
    default  => sub { LWP::UserAgent->new() },
);

# We really want to avoid downloading a real file when running the tests,
# since the number of downloads per day per ip address is limited.
my $BASE_URL
    = $ENV{HARNESS_ACTIVE}
    ? q{}
    : 'http://www.stopforumspam.com/downloads/';

# We want this settable via the constructor for testing
has _uri_base => (
    is      => 'ro',
    isa     => 'URI',
    default => sub { URI->new($BASE_URL) },
);

sub download {
    my $self = shift;
    my ( $type, $days ) = validated_list(
        \@_,
        type => { isa => DownloadType },
        days => { isa => DownloadDays },
    );

    my $uri = $self->_make_uri( $type, $days );

    my $response = $self->_ua()->get($uri);

    die "Could not fetch file at $uri: " . $response->message()
        unless $response->is_success();

    return $response->decoded_content();
}

sub download_and_save {
    my $self = shift;
    my ( $type, $days ) = validated_list(
        \@_,
        type => { isa => DownloadType },
        days => { isa => DownloadDays },
    );

    my $uri = $self->_make_uri( $type, $days );

    my $request = HTTP::Request->new( GET => $uri );

    my $dir = dir( tempdir( CLEANUP => 1 ) );
    my $file = $dir->file( $self->_make_file( $type, $days ) );

    my $response = $self->_ua()->request( $request, $file->stringify() );

    die "Could not fetch file at $uri: " . $response->message()
        unless $response->is_success();

    return $file;
}

sub _make_uri {
    my $self = shift;

    my $file = $self->_make_file(@_);

    my $uri = $self->_uri_base()->clone();

    my $new_path = $uri->path();
    $new_path .= '/' unless $new_path =~ m{/$};
    $new_path .= $file;

    $uri->path($new_path);

    return $uri;
}

sub _make_file {
    my $self = shift;
    my $type = shift;
    my $days = shift;

    return 'listed_' . $type . '_' . $days . '.zip';
}

1;
