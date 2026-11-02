<?php

namespace App\Console\Commands;

use App\Models\Payment;
use App\Models\Rental;
use App\Models\RentPeriod;
use Carbon\Carbon;
use Illuminate\Console\Command;

class RolloverRentPeriods extends Command
{
    protected $signature = 'rent:rollover {--month= : Mois à ouvrir (AAAA-MM), défaut : mois courant}';

    protected $description = 'Ouvre la période de loyer du mois pour chaque location active et reporte les impayés.';

    public function handle(): int
    {
        $month = $this->option('month')
            ? Carbon::createFromFormat('Y-m', $this->option('month'))->startOfMonth()
            : now()->startOfMonth();

        $period = $month->format('Y-m');
        $previous = $month->copy()->subMonth()->format('Y-m');
        $created = 0;

        Rental::with('housing')->where('status', 'ACTIVE')->each(function (Rental $rental) use ($period, $previous, $month, &$created) {
            if (RentPeriod::where('rental_id', $rental->id)->where('period', $period)->exists()) {
                return;
            }

            $carried = $this->unpaidOf($rental, $previous);
            $dueDay = min((int) $rental->housing->due_day, $month->daysInMonth);

            RentPeriod::create([
                'rental_id' => $rental->id,
                'period' => $period,
                'total' => $rental->housing->rent,
                'carried_over' => $carried,
                'due_date' => $month->copy()->day($dueDay)->toDateString(),
            ]);
            $created++;
        });

        $this->info("{$created} période(s) ouverte(s) pour {$period}.");

        return self::SUCCESS;
    }

    private function unpaidOf(Rental $rental, string $period): int
    {
        $previous = RentPeriod::where('rental_id', $rental->id)->where('period', $period)->first();

        if (! $previous) {
            return 0;
        }

        $paid = (int) Payment::where('rental_id', $rental->id)
            ->where('period', $period)
            ->where('status', 'SUCCESS')
            ->sum('amount');

        return max(0, $previous->total + $previous->carried_over - $paid);
    }
}
