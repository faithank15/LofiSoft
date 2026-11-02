<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Housing;
use App\Models\Payment;
use App\Models\Rental;
use App\Models\RentPeriod;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RentalController extends Controller
{
    public function join(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => ['required', 'string'],
        ]);

        $user = $request->user();

        // Règle 409 : un locataire ne peut avoir qu'une seule location ACTIVE ou PENDING
        $existing = Rental::where('tenant_id', $user->id)
            ->whereIn('status', ['ACTIVE', 'PENDING'])
            ->exists();

        if ($existing) {
            return response()->json([
                'message' => 'Vous avez déjà une location active ou en attente.',
            ], Response::HTTP_CONFLICT);
        }

        $housing = Housing::where('code', strtoupper(trim($validated['code'])))->first();

        if (! $housing) {
            return response()->json([
                'message' => 'Ce code ne correspond à aucun logement.',
            ], Response::HTTP_NOT_FOUND);
        }

        if ($housing->activeRental()->exists()) {
            return response()->json([
                'message' => 'Ce logement est déjà occupé.',
            ], Response::HTTP_CONFLICT);
        }

        $rental = Rental::create([
            'housing_id' => $housing->id,
            'tenant_id' => $user->id,
            'status' => 'PENDING',
            'started_at' => now()->toDateString(),
        ]);

        return response()->json([
            'message' => 'Demande envoyée au propriétaire.',
            'rental' => $rental,
        ], Response::HTTP_CREATED);
    }

    public function currentRental(Request $request): JsonResponse
    {
        $rental = Rental::with('housing.owner')
            ->where('tenant_id', $request->user()->id)
            ->where('status', 'ACTIVE')
            ->first();

        if (! $rental) {
            return response()->json(['message' => 'Aucune location active.'], Response::HTTP_NOT_FOUND);
        }

        return response()->json(['data' => $rental]);
    }

    public function end(Request $request, Rental $rental): JsonResponse
    {
        if ($rental->housing->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        $rental->update([
            'status' => 'FINISHED',
            'ended_at' => now()->toDateString(),
        ]);

        return response()->json(['message' => 'Location terminée.']);
    }

    public function currentRent(Request $request): JsonResponse
    {
        $rental = Rental::with('housing')
            ->where('tenant_id', $request->user()->id)
            ->where('status', 'ACTIVE')
            ->first();

        if (! $rental) {
            return response()->json(['message' => 'Aucune location en cours.'], Response::HTTP_NOT_FOUND);
        }

        $currentPeriod = now()->format('Y-m');
        $dueDay = str_pad((string) $rental->housing->due_day, 2, '0', STR_PAD_LEFT);
        $dueDate = now()->format('Y-m') . '-' . $dueDay;

        $periodRecord = RentPeriod::firstOrCreate(
            ['rental_id' => $rental->id, 'period' => $currentPeriod],
            [
                'total' => $rental->housing->rent,
                'carried_over' => 0,
                'due_date' => $dueDate,
            ]
        );

        $totalDue = (int) $periodRecord->total + (int) $periodRecord->carried_over;

        $paid = (int) Payment::where('rental_id', $rental->id)
            ->where('period', $currentPeriod)
            ->where('status', 'SUCCESS')
            ->sum('amount');

        $remaining = max(0, $totalDue - $paid);

        $status = 'UPCOMING';
        if ($paid >= $totalDue) {
            $status = 'PAID';
        } elseif ($paid > 0) {
            $status = 'PARTIAL';
        } elseif (now()->isAfter(Carbon::parse($dueDate))) {
            $status = 'LATE';
        }

        return response()->json([
            'period' => $currentPeriod,
            'label' => Carbon::now()->locale('fr')->isoFormat('MMMM'),
            'total' => $totalDue,
            'paid' => $paid,
            'remaining' => $remaining,
            'due_date' => $dueDate,
            'status' => $status,
        ]);
    }

    public function rentPeriods(Request $request): JsonResponse
    {
        $rental = Rental::where('tenant_id', $request->user()->id)
            ->where('status', 'ACTIVE')
            ->first();

        if (! $rental) {
            return response()->json(['data' => []]);
        }

        $periods = RentPeriod::where('rental_id', $rental->id)->latest('period')->get();

        return response()->json(['data' => $periods]);
    }
}
