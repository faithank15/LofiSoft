<?php

namespace App\Models;

use App\Enums\AnnouncementStatus;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Announcement extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'rental_unit_id',
        'titre',
        'description',
        'loyer_mensuel',
        'ville',
        'quartier',
        'adresse',
        'point_repere',
        'latitude',
        'longitude',
        'statut',
        'date_publication',
    ];

    protected function casts(): array
    {
        return [
            'statut' => AnnouncementStatus::class,
            'loyer_mensuel' => 'decimal:2',
            'latitude' => 'decimal:8',
            'longitude' => 'decimal:8',
            'date_publication' => 'datetime',
        ];
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function rentalUnit(): BelongsTo
    {
        return $this->belongsTo(RentalUnit::class);
    }

    public function photos(): HasMany
    {
        return $this->hasMany(AnnouncementPhoto::class)->orderBy('ordre');
    }

    public function reports(): HasMany
    {
        return $this->hasMany(Report::class);
    }
}
