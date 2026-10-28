<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Installment extends Model
{
    use HasUuids;

    protected $fillable = [
        'rental_id',
        'date_debut',
        'date_fin',
        'montant_du',
        'montant_paye',
        'est_solde',
    ];

    protected function casts(): array
    {
        return [
            'date_debut' => 'date',
            'date_fin' => 'date',
            'montant_du' => 'decimal:2',
            'montant_paye' => 'decimal:2',
            'est_solde' => 'boolean',
        ];
    }

    public function rental(): BelongsTo
    {
        return $this->belongsTo(Rental::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }
}
