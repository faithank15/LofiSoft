<?php

namespace App\Services;

use App\Models\Payment;
use App\Models\Rental;
use App\Models\RentPeriod;

/** Calcul du solde d'une période de loyer : dû (loyer + report) moins paiements réussis. */
class RentBalance
{
    public function due(Rental $rental, string $period): int
    {
        $record = RentPeriod::where('rental_id', $rental->id)->where('period', $period)->first();

        return $record ? (int) ($record->total + $record->carried_over) : (int) $rental->housing->rent;
    }

    public function paid(Rental $rental, string $period): int
    {
        return (int) Payment::where('rental_id', $rental->id)
            ->where('period', $period)
            ->where('status', 'SUCCESS')
            ->sum('amount');
    }

    public function remaining(Rental $rental, string $period): int
    {
        return max(0, $this->due($rental, $period) - $this->paid($rental, $period));
    }
}
