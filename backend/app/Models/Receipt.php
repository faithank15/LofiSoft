<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Receipt extends Model
{
    use HasUuids;

    protected $fillable = [
        'payment_id',
        'numero_recu',
        'date_emission',
        'montant_paye',
        'details',
    ];

    protected function casts(): array
    {
        return [
            'date_emission' => 'datetime',
            'montant_paye' => 'decimal:2',
            'details' => 'array',
        ];
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }
}
