<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\Rental;
use App\Models\RentPeriod;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

class OwnerDashboardController extends Controller
{
    public function dashboard(Request $request): JsonResponse
    {
        $owner = $request->user();
        $housingIds = $owner->housings()->pluck('id');
        $currentMonth = now()->format('Y-m');

        $activeRentals = Rental::whereIn('housing_id', $housingIds)
            ->where('status', 'ACTIVE')
            ->get();

        $expected = (int) $owner->housings()->whereHas('activeRental')->sum('rent');

        $received = (int) Payment::whereIn('rental_id', $activeRentals->pluck('id'))
            ->where('period', $currentMonth)
            ->where('status', 'SUCCESS')
            ->sum('amount');

        $lateCount = 0;
        foreach ($activeRentals as $rental) {
            $dueDay = str_pad((string) $rental->housing->due_day, 2, '0', STR_PAD_LEFT);
            $dueDate = now()->format('Y-m') . '-' . $dueDay;

            if (now()->isAfter(Carbon::parse($dueDate))) {
                $paid = (int) Payment::where('rental_id', $rental->id)
                    ->where('period', $currentMonth)
                    ->where('status', 'SUCCESS')
                    ->sum('amount');

                if ($paid < $rental->housing->rent) {
                    $lateCount++;
                }
            }
        }

        return response()->json([
            'month' => $currentMonth,
            'expected' => $expected,
            'received' => $received,
            'late_count' => $lateCount,
            'tenants_count' => $activeRentals->count(),
            'housings_count' => $housingIds->count(),
        ]);
    }

    public function tenants(Request $request): JsonResponse
    {
        $owner = $request->user();
        $housingIds = $owner->housings()->pluck('id');
        $currentMonth = now()->format('Y-m');

        $rentals = Rental::with(['housing', 'tenant'])
            ->whereIn('housing_id', $housingIds)
            ->where('status', 'ACTIVE')
            ->get();

        $data = $rentals->map(function ($rental) use ($currentMonth) {
            $period = RentPeriod::where('rental_id', $rental->id)->where('period', $currentMonth)->first();
            $carriedOver = $period ? (int) $period->carried_over : 0;
            $due = $period ? ($period->total + $carriedOver) : (int) $rental->housing->rent;

            $paid = (int) Payment::where('rental_id', $rental->id)
                ->where('period', $currentMonth)
                ->where('status', 'SUCCESS')
                ->sum('amount');

            $dueDay = str_pad((string) $rental->housing->due_day, 2, '0', STR_PAD_LEFT);
            $dueDate = now()->format('Y-m') . '-' . $dueDay;

            $status = 'UPCOMING';
            if ($paid >= $due) {
                $status = 'PAID';
            } elseif ($paid > 0) {
                $status = 'PARTIAL';
            } elseif (now()->isAfter(Carbon::parse($dueDate))) {
                $status = 'LATE';
            }

            return [
                'rental_id' => (string) $rental->id,
                'tenant_name' => trim(($rental->tenant?->prenoms ?? '') . ' ' . ($rental->tenant?->nom ?? '')),
                'housing' => $rental->housing->title,
                'due' => $due,
                'carried_over' => $carriedOver,
                'status' => $status,
            ];
        });

        if ($request->query('status') === 'LATE') {
            $data = $data->where('status', 'LATE')->values();
        }

        return response()->json($data);
    }

    public function tenantDetails(Request $request, string $rentalId): JsonResponse
    {
        $rental = Rental::with(['housing', 'tenant'])->findOrFail($rentalId);

        if ($rental->housing->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        $payments = Payment::where('rental_id', $rental->id)->latest('created_at')->get();

        return response()->json([
            'rental' => $rental,
            'payments' => $payments,
        ]);
    }

    public function acceptRental(Request $request, Rental $rental): JsonResponse
    {
        if ($rental->housing->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        $rental->update(['status' => 'ACTIVE']);

        return response()->json(['message' => 'Locataire confirmé.']);
    }

    public function rejectRental(Request $request, Rental $rental): JsonResponse
    {
        if ($rental->housing->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        $rental->delete();

        return response()->json(['message' => 'Demande refusée.']);
    }

    public function remind(Request $request, Rental $rental): JsonResponse
    {
        return response()->json(['message' => 'Rappel envoyé au locataire.']);
    }

    public function manualPayment(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'rental_id' => ['required', 'uuid', 'exists:rentals,id'],
            'period' => ['required', 'string', 'regex:/^[0-9]{4}-[0-9]{2}$/'],
            'amount' => ['required', 'integer', 'min:1'],
            'note' => ['nullable', 'string'],
        ]);

        $rental = Rental::with('housing')->findOrFail($validated['rental_id']);

        if ($rental->housing->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        $payment = Payment::create([
            'rental_id' => $rental->id,
            'period' => $validated['period'],
            'amount' => $validated['amount'],
            'operator' => 'CASH',
            'phone' => $rental->tenant?->telephone ?? '0100000000',
            'status' => 'SUCCESS',
            'paid_at' => now(),
            'reference' => 'CASH-' . date('Ymd') . '-' . Str::upper(Str::random(4)),
            'note' => $validated['note'] ?? null,
        ]);

        return response()->json(['message' => 'Paiement en espèces enregistré.', 'payment' => $payment], Response::HTTP_CREATED);
    }
}
