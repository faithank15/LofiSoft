<?php

namespace App\Enums;

enum UserRole: string
{
    case TENANT = 'TENANT';
    case OWNER = 'OWNER';
    case ADMIN = 'ADMIN';
}
