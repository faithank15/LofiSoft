<?php

namespace App\Models;

use App\Enums\AccommodationType;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class RentalUnit extends Model
{
    use HasUuids;

    protected $fillable = [
        'property_id',
        'nom',
        'description',
        'adresse',
        'type',
        'loyer_mensuel',
        'code_logement',
        'est_disponible',
    ];

    protected function casts(): array
    {
        return [
            'type' => AccommodationType::class,
            'loyer_mensuel' => 'decimal:2',
            'est_disponible' => 'boolean',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (RentalUnit $unit) {
            if (empty($unit->code_logement)) {
                $unit->code_logement = self::generateUniqueCode();
            }
        });
    }

    public static function generateUniqueCode(): string
    {
        do {
            $first = Str::upper(Str::random(3));
            $second = Str::upper(Str::random(3));
            $code = "{$first}-{$second}";
        } while (self::where('code_logement', $code)->exists());

        return $code;
    }

    public function property(): BelongsTo
    {
        return $this->belongsTo(Property::class);
    }

    public function rentals(): HasMany
    {
        return $this->hasMany(Rental::class);
    }

    public function activeRental(): HasOne
    {
        return $this->hasOne(Rental::class)->where('statut', 'ACTIVE');
    }

    public function announcement(): HasOne
    {
        return $this->hasOne(Announcement::class);
    }
}
