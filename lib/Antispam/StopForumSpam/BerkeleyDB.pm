package Antispam::StopForumSpam::BerkeleyDB;

use strict;
use warnings;
use namespace::autoclean;

use Antispam::StopForumSpam::Types qw( Bool File SFSTextFile );

use Moose;
use MooseX::Params::Validate qw( validated_hash );
use MooseX::StrictConstructor;

with 'Antispam::Toolkit::Role::BerkeleyDB';

# We end up going through the validation code twice this way, but
# unfortunately there's really no better way to require a more specific type
# for the file parameter in this class versus the
# Antispam::Toolkit::Role::BerkeleyDB role.
around build => sub {
    my $orig  = shift;
    my $class = shift;
    my %p     = validated_hash(
        \@_,
        file => {
            isa    => SFSTextFile,
            coerce => 1,
        },
        database => {
            isa    => File,
            coerce => 1,
        },
        update => {
            isa     => Bool,
            default => 0,
        },
    );

    $class->$orig(%p);
};

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Manage Berkeley DB files based on StopForumSpam data

__END__

=head1 SYNOPSIS

  Antispam::StopForumSpam::BerkeleyDB->build(
      file     => '/tmp/listed_email_7.zip',
      database => '/var/lib/sfs/listed_email_7/listed_email_7.db',
  );

  my $db = Antispam::StopForumSpam::BerkeleyDB->new(
      database => '/var/lib/sfs/listed_email_7/listed_email_7.db',
  );

=head1 DESCRIPTION

This class provides a concrete implementation of the
L<Antispam::Toolkit::Role::BerkeleyDB> role.

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
