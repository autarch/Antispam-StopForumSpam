package Antispam::StopForumSpam;

use strict;
use warnings;

use Antispam::StopForumSpam::Types qw( NonEmptyStr SFSDatabase );
use Antispam::Toolkit::Result;

use Moose;
use MooseX::StrictConstructor;

with qw(
    Antispam::Toolkit::Role::EmailChecker
    Antispam::Toolkit::Role::IPChecker
    Antispam::Toolkit::Role::UsernameChecker
);

my @Types = qw( ip email username );

for my $type ( map { $_ . '_database' } @Types ) {
    has $type => (
        is        => 'ro',
        isa       => SFSDatabase,
        predicate => '_has_' . $type,
    );
}

sub BUILD {
    my $self = shift;

    die 'You must provide at least one database when constructing an '
        . ( ref $self )
        . ' object'
        unless $self->_has_email_database()
            || $self->_has_ip_database()
            || $self->_has_username_database();
}

sub check_email {
    my $self = shift;

    $self->_check( 'email', @_ );
}

sub check_ip {
    my $self = shift;

    $self->_check( 'ip', @_ );
}

sub check_username {
    my $self = shift;

    $self->_check( 'username', @_ );
}

sub _check {
    my $self = shift;
    my $type = shift;
    my %p    = @_;

    my $pred = '_has_' . $type . '_database';

    return unless $self->$pred();

    my @details;

    my $db = $type . '_database';

    my $score = 0;
    if ( $self->$db()->match_value( $p{$type} ) ) {
        $score = 1;

        push @details,
            sprintf(
            'The %s (%s) was found in a StopForumSpam database (%s)',
            $type,
            $p{$type},
            $self->$db()->name(),
            );
    }
    else {
        push @details,
            sprintf(
            'The %s (%s) was not found in a StopForumSpam database (%s)',
            $type,
            $p{$type},
            $self->$db()->name(),
            );
    }

    return Antispam::Toolkit::Result->new(
        score   => $score,
        details => \@details,
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Antispam checks using StopForumSpam.com's antispam databases

__END__

=head1 SYNOPSIS

  my $bl = Antispam::StopForumSpam->new( email_database => '/path/to/file.db' );

  my $result = $bl->check_email( ip => '1.2.3.4' );

  if ( $result->score() ) { ... }

=head1 DESCRIPTION

This module implements the L<Antispam::Toolkit::Role::EmailChecker>,
L<Antispam::Toolkit::Role::IPChecker>,
L<Antispam::Toolkit::Role::UsernameChecker> roles using the antispam databases
which can be downloaded from the L<http://stopforumspam.com> website.

Please note that as of this writing, these databases are free for
non-commercial use only.

=head1 METHODS

This class provides the following methods:

=head2 Antispam::StopForumSpam->new(...)

This method constructs a new object. It requires at least one of three keys,
C<email_database>, C<ip_database>, or C<username_database>.

These databases must be objects which do the
L<Antispam::Toolkit::Role::Database> role.

=head2 $sfs->check_email( email => ... )

This method checks whether an email address is associated with some sort of
spam-related behavior.

It returns an L<Antispam::Toolkit::Result> object. The result's score will be
either 0 or 1.

=head2 $sfs->check_ip( ip => ... )

This method checks whether an ip address is associated with some sort of
spam-related behavior.

It returns an L<Antispam::Toolkit::Result> object. The result's score will be
either 0 or 1.

=head2 $sfs->check_username( username => ... )

This method checks whether an username is associated with some sort of
spam-related behavior.

It returns an L<Antispam::Toolkit::Result> object. The result's score will be
either 0 or 1.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-antispam-stopforumspam@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=cut
