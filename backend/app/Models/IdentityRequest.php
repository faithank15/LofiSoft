<?php

namespace App\Models;

use App\Enums\IdentityStatus;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class IdentityRequest extends Model
{
    use HasUuids;

    protected $fillable = [
        'owner_id',
        'id_image_url',
        'selfie_url',
        'status',
        'reason',
        'reviewed_by',
    ];

    protected function casts(): array
    {
        return [
            'status' => IdentityStatus::class,
        ];
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
