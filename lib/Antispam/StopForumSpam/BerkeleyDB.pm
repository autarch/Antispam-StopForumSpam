package Antispam::StopForumSpam::BerkeleyDB;

use strict;
use warnings;
use namespace::autoclean;

use Antispam::StopForumSpam::Types qw( File SFSTextFile );

use Moose;
use MooseX::Params::Validate qw( validated_hash );
use MooseX::StrictConstructor;

with 'Antispam::Toolkit::Role::BerkeleyDB';

# We end up going through the validation code twice this way, but
# unfortunately there's really no better way to specify a more specific type
# for the file parameter in this class versus the
# Antispam::Toolkit::Role::BerkeleyDB role.
around build => sub {
    my $orig = shift;
    my $class = shift;
    my %p = validated_hash(
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

    $class->$orig(%p);
};

sub _store_value {
    my $self  = shift;
    my $db    = shift;
    my $value = shift;

    $db->db_put( $value => 1 )
        and die "Fatal error trying to write to the BerkeleyDB file at "
        . $self->database();

    return;
}

__PACKAGE__->meta()->make_immutable();

1;
