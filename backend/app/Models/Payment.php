<?php

namespace App\Models;

use App\Enums\Operator;
use App\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    use HasUuids;

    protected $fillable = [
        'rental_id',
        'period',
        'amount',
        'operator',
        'phone',
        'status',
        'reference',
        'provider_ref',
        'paid_at',
        'note',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'operator' => Operator::class,
            'status' => PaymentStatus::class,
            'paid_at' => 'datetime',
        ];
    }

    public function rental(): BelongsTo
    {
        return $this->belongsTo(Rental::class);
    }
}
