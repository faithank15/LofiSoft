<?php

namespace App\Enums;

enum RentalStatus: string
{
    case PENDING = 'PENDING';
    case ACTIVE = 'ACTIVE';
    case FINISHED = 'FINISHED';
}
