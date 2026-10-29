<?php

namespace App\Enums;

enum AnnouncementStatus: string
{
    case DRAFT = 'DRAFT';
    case PUBLISHED = 'PUBLISHED';
    case CANCELED = 'CANCELED';
    case CLOSED = 'CLOSED';
}
