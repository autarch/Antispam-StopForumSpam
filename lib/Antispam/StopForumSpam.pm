package Antispam::StopForumSpam;

use strict;
use warnings;

use Antispam::StopForumSpam::Types qw( NonEmptyStr SFSDatabase );
use Antispam::Toolkit::Result;

use Moose;
use MooseX::StrictConstructor;

with qw(
    Antispam::Toolkit::Role::LinkChecker
    Antispam::Toolkit::Role::UserChecker
);

for my $type ( map { $_ . '_database' } qw( ip email link username ) ) {
    has $type => (
        is        => 'ro',
        isa       => SFSDatabase,
        predicate => '_has_' . $type,
    );
}

sub check_user {
    my $self = shift;

    $self->_check( \@_, qw( ip email username ) );
}

sub check_link {
    my $self = shift;

    $self->_check( \@_, qw( ip email link username ) );
}

sub _check {
    my $self  = shift;
    my $args  = shift;
    my @types = @_;

    my @details;
    for my $type (@types) {
        my $db   = $type . '_database';
        my $pred = '_has_' . $db;

        next unless $self->$pred();

        next unless $self->$db()->contains_value( $p{$type} );

        push @details,
            sprintf(
            'The %1 (%2) was found in a StopForumSpam database (%3)',
            $type,
            $p{$type},
            $self->$db()->name(),
            );
    }

    return Antispam::Toolkit::Result->new(
        is_spam => ( scalar @details ? 1 : 0 ),
        details => \@details,
    );
}

__PACKAGE__->meta()->make_immutable();

1;
