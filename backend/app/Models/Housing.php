<?php

namespace App\Models;

use App\Enums\AccommodationType;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class Housing extends Model
{
    use HasUuids;

    protected $fillable = [
        'owner_id',
        'title',
        'type',
        'rent',
        'due_day',
        'city',
        'district',
        'code',
        'photos',
    ];

    protected function casts(): array
    {
        return [
            'type' => AccommodationType::class,
            'rent' => 'integer',
            'due_day' => 'integer',
            'photos' => 'array',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Housing $housing) {
            if (empty($housing->code)) {
                $housing->code = self::generateUniqueCode();
            }
        });
    }

    public static function generateUniqueCode(): string
    {
        do {
            $code = Str::upper(Str::random(3)) . '-' . Str::upper(Str::random(3));
        } while (self::where('code', $code)->exists());

        return $code;
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function rentals(): HasMany
    {
        return $this->hasMany(Rental::class);
    }

    public function activeRental(): HasOne
    {
        return $this->hasOne(Rental::class)->where('status', 'ACTIVE');
    }

    public function announcement(): HasOne
    {
        return $this->hasOne(Announcement::class);
    }
}
