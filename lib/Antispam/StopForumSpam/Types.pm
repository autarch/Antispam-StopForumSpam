package Antispam::StopForumSpam::Types;

use strict;
use warnings;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        Antispam::StopForumSpam::Types::Internal
        MooseX::Types::Common::String
        MooseX::Types::Moose
        MooseX::Types::Path::Class
        )
);

1;
