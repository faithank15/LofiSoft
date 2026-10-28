<?php

namespace App\Models;

use App\Enums\RentalStatus;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Rental extends Model
{
    use HasUuids;

    protected $fillable = [
        'housing_id',
        'tenant_id',
        'status',
        'started_at',
        'ended_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => RentalStatus::class,
            'started_at' => 'date',
            'ended_at' => 'date',
        ];
    }

    public function housing(): BelongsTo
    {
        return $this->belongsTo(Housing::class);
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'tenant_id');
    }

    public function periods(): HasMany
    {
        return $this->hasMany(RentPeriod::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }
}
