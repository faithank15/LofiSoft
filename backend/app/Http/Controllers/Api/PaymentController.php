<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\Rental;
use App\Models\RentPeriod;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

class PaymentController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'rental_id' => ['required', 'uuid', 'exists:rentals,id'],
            'period' => ['required', 'string', 'regex:/^[0-9]{4}-[0-9]{2}$/'],
            'amount' => ['required', 'integer', 'min:1'],
            'operator' => ['required', 'string', 'in:MTN,MOOV'],
            'phone' => ['required', 'string', 'regex:/^01[0-9]{8}$/'],
        ]);

        $rental = Rental::with('housing')->findOrFail($validated['rental_id']);

        if ($rental->tenant_id !== $request->user()->id) {
            return response()->json(['message' => 'Cette location ne vous appartient pas.'], Response::HTTP_FORBIDDEN);
        }

        $period = RentPeriod::where('rental_id', $rental->id)->where('period', $validated['period'])->first();
        $totalDue = $period ? ($period->total + $period->carried_over) : $rental->housing->rent;

        $alreadyPaid = (int) Payment::where('rental_id', $rental->id)
            ->where('period', $validated['period'])
            ->where('status', 'SUCCESS')
            ->sum('amount');

        $remaining = max(0, $totalDue - $alreadyPaid);

        if ($validated['amount'] > $remaining) {
            return response()->json([
                'message' => 'Le montant dépasse le solde restant à payer.',
                'errors' => ['amount' => ['Le montant ne peut pas dépasser ' . $remaining . ' FCFA.']],
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $payment = Payment::create([
            'rental_id' => $rental->id,
            'period' => $validated['period'],
            'amount' => $validated['amount'],
            'operator' => $validated['operator'],
            'phone' => $validated['phone'],
            'status' => 'PENDING',
            'reference' => 'RC-' . date('Ymd') . '-' . Str::upper(Str::random(4)),
        ]);

        return response()->json([
            'payment' => [
                'id' => (string) $payment->id,
                'status' => 'PENDING',
                'amount' => (int) $payment->amount,
                'operator' => $payment->operator->value,
            ],
        ], Response::HTTP_CREATED);
    }

    public function show(Payment $payment): JsonResponse
    {
        return response()->json([
            'id' => (string) $payment->id,
            'status' => $payment->status->value,
            'amount' => (int) $payment->amount,
            'operator' => $payment->operator->value,
        ]);
    }

    public function myPayments(Request $request): JsonResponse
    {
        $rentals = Rental::where('tenant_id', $request->user()->id)->pluck('id');

        $payments = Payment::whereIn('rental_id', $rentals)
            ->latest('created_at')
            ->paginate((int) $request->input('per_page', 20));

        $data = collect($payments->items())->map(function ($p) {
            return [
                'id' => (string) $p->id,
                'amount' => (int) $p->amount,
                'operator' => $p->operator->value,
                'paid_at' => $p->paid_at?->toISOString(),
                'period' => $p->period,
                'status' => $p->status->value,
            ];
        });

        return response()->json([
            'data' => $data,
            'meta' => [
                'current_page' => $payments->currentPage(),
                'last_page' => $payments->lastPage(),
                'total' => $payments->total(),
            ],
        ]);
    }

    public function receipt(Payment $payment): JsonResponse
    {
        if ($payment->status->value !== 'SUCCESS') {
            return response()->json(['message' => 'Aucun reçu disponible pour un paiement non abouti.'], Response::HTTP_BAD_REQUEST);
        }

        $payment->load('rental.housing');

        return response()->json([
            'reference' => $payment->reference,
            'amount' => (int) $payment->amount,
            'paid_at' => $payment->paid_at?->toISOString(),
            'operator' => $payment->operator->value === 'MTN' ? 'MTN Mobile Money' : ($payment->operator->value === 'MOOV' ? 'Moov Money' : 'Espèces'),
            'housing' => $payment->rental?->housing?->title ?? '',
            'period' => $payment->period,
        ]);
    }

    public function webhook(Request $request): JsonResponse
    {
        $reference = $request->input('reference');
        $status = $request->input('status') === 'approved' ? 'SUCCESS' : 'FAILED';

        $payment = Payment::where('reference', $reference)->first();

        if ($payment) {
            $payment->update([
                'status' => $status,
                'paid_at' => $status === 'SUCCESS' ? now() : null,
                'provider_ref' => $request->input('transaction_id'),
            ]);
        }

        return response()->json(['received' => true]);
    }
}
