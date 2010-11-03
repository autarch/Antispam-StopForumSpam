package Antispam::StopForumSpam::Types::Internal;

use strict;
use warnings;

use IO::Handle;

use MooseX::Types -declare => [
    qw(
        DownloadDays
        DownloadType
        )
];

enum DownloadDays, ( 1, 7, 30, 90, 180, 365 );

enum DownloadType, qw( ip email username );

1;
