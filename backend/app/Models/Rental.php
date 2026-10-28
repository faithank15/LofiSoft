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
        'rental_unit_id',
        'tenant_id',
        'date_debut',
        'date_fin',
        'loyer_mensuel',
        'caution',
        'jour_echeance',
        'periodicite',
        'statut',
    ];

    protected function casts(): array
    {
        return [
            'statut' => RentalStatus::class,
            'date_debut' => 'date',
            'date_fin' => 'date',
            'loyer_mensuel' => 'decimal:2',
            'caution' => 'decimal:2',
            'jour_echeance' => 'integer',
        ];
    }

    public function rentalUnit(): BelongsTo
    {
        return $this->belongsTo(RentalUnit::class);
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'tenant_id');
    }

    public function installments(): HasMany
    {
        return $this->hasMany(Installment::class);
    }
}
