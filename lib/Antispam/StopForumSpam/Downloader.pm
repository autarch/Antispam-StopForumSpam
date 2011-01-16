package Antispam::StopForumSpam::Downloader;

use strict;
use warnings;
use namespace::autoclean;

use Antispam::StopForumSpam::Types qw( DownloadDays DownloadType Str URIObject );
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

has uri_base => (
    is      => 'ro',
    isa     => URIObject,
    coerce  => 1,
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

    my $uri = $self->uri_base()->clone();

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

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Downloads data from the stopforumspam.com website

__END__

=head1 SYNOPSIS

  my $dl = Antispam::StopForumSpam::Downloader->new();

  my $content = $dl->download(
      type => 'email',
      days => 30,
  );

  my $file = $dl->download_and_save(
      type => 'ip',
      days => 180,
  );

=head1 DESCRIPTION

This class knows how to download data files from the
L<http://stopforumspam.com> website.

=head2 License and Terms of Service

While this code is free software, the data from the Stop Forum Spam site has
its own license.

As of this writing (November, 2010), it is under a Creative Commons license
that forbids commercial use

=head1 METHODS

This class consumes all the methods (and attributes) of
L<Antispam::Toolkit::Role::BerkeleyDB> as-is, except for the C<<
$class->build() >> method.

The build method will accept a zip file downloaded from the
L<http://stopforumspam.com> website. You do not need to unzip it first.

=head1 ROLES

This class does the L<Antispam::Toolkit::Role::BerkeleyDB> role.

=head1 BUGS

See L<Antispam::StopForumSpam> for bug reporting details.

=cut
