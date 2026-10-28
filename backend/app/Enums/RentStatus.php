<?php

namespace App\Enums;

enum RentStatus: string
{
    case PAID = 'PAID';
    case PARTIAL = 'PARTIAL';
    case LATE = 'LATE';
    case UPCOMING = 'UPCOMING';
}
