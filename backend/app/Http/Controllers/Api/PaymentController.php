<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\Rental;
use App\Services\RentBalance;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class PaymentController extends Controller
{
    public function store(Request $request, RentBalance $balance): JsonResponse
    {
        $validated = $request->validate([
            'rental_id' => ['required', 'uuid', 'exists:rentals,id'],
            'period' => ['required', 'string', 'regex:/^[0-9]{4}-(0[1-9]|1[0-2])$/'],
            'amount' => ['required', 'integer', 'min:1'],
            'operator' => ['required', 'string', 'in:MTN,MOOV'],
            'phone' => ['required', 'string', 'regex:/^01[0-9]{8}$/'],
        ]);

        $rental = Rental::with('housing')->findOrFail($validated['rental_id']);

        if ($rental->tenant_id !== $request->user()->id) {
            return response()->json(['message' => 'Cette location ne vous appartient pas.'], Response::HTTP_FORBIDDEN);
        }

        if ($rental->status->value !== 'ACTIVE') {
            return response()->json(['message' => 'Cette location n\'est pas active.'], Response::HTTP_CONFLICT);
        }

        $remaining = $balance->remaining($rental, $validated['period']);

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

    public function show(Request $request, Payment $payment): JsonResponse
    {
        $this->authorizeTenant($request, $payment);
        $this->settleSimulated($payment);

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

    public function receipt(Request $request, Payment $payment): JsonResponse
    {
        $this->authorizeTenant($request, $payment);

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
        $secret = config('services.kkiapay.secret');

        if (filled($secret)) {
            $sent = (string) $request->header('x-kkiapay-secret', '');
            if (! hash_equals($secret, $sent)) {
                return response()->json(['message' => 'Signature invalide.'], Response::HTTP_UNAUTHORIZED);
            }
        } elseif (app()->isProduction()) {
            return response()->json(['message' => 'Webhook non configuré.'], Response::HTTP_SERVICE_UNAVAILABLE);
        }

        $reference = $request->input('reference');
        $status = $request->input('status') === 'approved' ? 'SUCCESS' : 'FAILED';

        $payment = Payment::where('reference', $reference)->first();

        // Idempotent : un paiement déjà conclu n'est plus modifié.
        if ($payment && $payment->status->value === 'PENDING') {
            $payment->update([
                'status' => $status,
                'paid_at' => $status === 'SUCCESS' ? now() : null,
                'provider_ref' => $request->input('transaction_id'),
            ]);
        }

        return response()->json(['received' => true]);
    }

    private function authorizeTenant(Request $request, Payment $payment): void
    {
        $owns = Rental::where('id', $payment->rental_id)
            ->where('tenant_id', $request->user()->id)
            ->exists();

        if (! $owns) {
            throw new AccessDeniedHttpException();
        }
    }

    /**
     * Mode simulé : après quelques secondes, l'opérateur « répond ».
     * Un numéro finissant par 00 échoue, tout autre réussit.
     */
    private function settleSimulated(Payment $payment): void
    {
        if (config('services.payments.driver') !== 'fake' || $payment->status->value !== 'PENDING') {
            return;
        }

        if ($payment->created_at->diffInSeconds(now()) < config('services.payments.fake_delay')) {
            return;
        }

        $ok = ! str_ends_with($payment->phone, '00');

        $payment->update([
            'status' => $ok ? 'SUCCESS' : 'FAILED',
            'paid_at' => $ok ? now() : null,
            'provider_ref' => 'SIM-'.Str::upper(Str::random(8)),
        ]);
    }
}
