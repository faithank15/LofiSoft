<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RentPeriod extends Model
{
    use HasUuids;

    protected $fillable = [
        'rental_id',
        'period',
        'total',
        'carried_over',
        'due_date',
    ];

    protected function casts(): array
    {
        return [
            'total' => 'integer',
            'carried_over' => 'integer',
            'due_date' => 'date',
        ];
    }

    public function rental(): BelongsTo
    {
        return $this->belongsTo(Rental::class);
    }
}
