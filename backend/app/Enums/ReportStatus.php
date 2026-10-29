<?php

namespace App\Enums;

enum ReportStatus: string
{
    case PENDING = 'PENDING';
    case RESOLVED = 'RESOLVED';
    case DISMISSED = 'DISMISSED';
}
