<?php

namespace Tests\Feature;

use App\Models\Payment;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PaymentTest extends TestCase
{
    private function body($rental, array $over = []): array
    {
        return $over + [
            'rental_id' => $rental->id,
            'period' => now()->format('Y-m'),
            'amount' => 50000,
            'operator' => 'MTN',
            'phone' => '0197000011',
        ];
    }

    public function test_store_creates_pending_payment(): void
    {
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 100000]);
        Sanctum::actingAs($tenant);

        $this->postJson('/api/payments', $this->body($rental))
            ->assertCreated()
            ->assertJsonPath('payment.status', 'PENDING')
            ->assertJsonPath('payment.amount', 50000)
            ->assertJsonPath('payment.operator', 'MTN');

        $payment = Payment::first();
        $this->assertMatchesRegularExpression('/^RC-\d{8}-[A-Z0-9]{4}$/', $payment->reference);
    }

    public function test_store_does_not_count_pending_towards_balance(): void
    {
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 100000]);
        Sanctum::actingAs($tenant);

        $this->postJson('/api/payments', $this->body($rental))->assertCreated();
        $this->getJson('/api/me/rent')->assertJsonPath('paid', 0);
    }

    /** @dataProvider invalid */
    public function test_store_validation(array $over, string $field): void
    {
        [, $tenant, , $rental] = $this->activeSetup();
        Sanctum::actingAs($tenant);

        $this->postJson('/api/payments', $this->body($rental, $over))->assertStatus(422)->assertJsonValidationErrors($field);
        $this->assertSame(0, Payment::count());
    }

    public static function invalid(): array
    {
        return [
            'montant zéro' => [['amount' => 0], 'amount'],
            'montant négatif' => [['amount' => -100], 'amount'],
            'montant décimal' => [['amount' => 10.5], 'amount'],
            'opérateur CASH interdit' => [['operator' => 'CASH'], 'operator'],
            'opérateur inconnu' => [['operator' => 'ORANGE'], 'operator'],
            'téléphone invalide' => [['phone' => '123'], 'phone'],
            'période invalide' => [['period' => '2026/10'], 'period'],
            'période mois 13' => [['period' => '2026-13'], 'period'],
            'location inconnue' => [['rental_id' => '00000000-0000-0000-0000-000000000000'], 'rental_id'],
        ];
    }

    public function test_store_rejects_amount_above_remaining_balance(): void
    {
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 100000]);
        Sanctum::actingAs($tenant);
        $this->payment($rental, 70000);

        $this->postJson('/api/payments', $this->body($rental, ['amount' => 30001]))
            ->assertStatus(422)->assertJsonValidationErrors('amount');
        $this->postJson('/api/payments', $this->body($rental, ['amount' => 30000]))->assertCreated();
    }

    public function test_store_counts_carried_over_in_the_limit(): void
    {
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 100000]);
        Sanctum::actingAs($tenant);
        $this->period($rental, now()->format('Y-m'), 100000, 40000);

        $this->postJson('/api/payments', $this->body($rental, ['amount' => 140000]))->assertCreated();
    }

    public function test_store_refuses_someone_elses_rental(): void
    {
        [, , , $rental] = $this->activeSetup();
        $this->actingAsRole('TENANT');

        $this->postJson('/api/payments', $this->body($rental))->assertForbidden();
        $this->assertSame(0, Payment::count());
    }

    public function test_store_refuses_non_active_rental(): void
    {
        [, $tenant, , $rental] = $this->activeSetup();
        $rental->update(['status' => 'PENDING']);
        Sanctum::actingAs($tenant);

        $this->postJson('/api/payments', $this->body($rental))->assertStatus(409);
        $rental->update(['status' => 'FINISHED']);
        $this->postJson('/api/payments', $this->body($rental))->assertStatus(409);
    }

    public function test_owner_cannot_pay(): void
    {
        [$owner, , , $rental] = $this->activeSetup();
        Sanctum::actingAs($owner);

        $this->postJson('/api/payments', $this->body($rental))->assertForbidden();
    }

    // ---- Simulation de l'opérateur ---------------------------------------------------

    public function test_fake_driver_settles_after_delay_as_success(): void
    {
        config(['services.payments.driver' => 'fake', 'services.payments.fake_delay' => 4]);
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 100000]);
        Sanctum::actingAs($tenant);

        $id = $this->postJson('/api/payments', $this->body($rental))->json('payment.id');

        $this->getJson("/api/payments/$id")->assertJsonPath('status', 'PENDING');
        $this->travel(5)->seconds();
        $this->getJson("/api/payments/$id")->assertJsonPath('status', 'SUCCESS');
        $this->getJson('/api/me/rent')->assertJsonPath('paid', 50000);
        $this->assertNotNull(Payment::find($id)->paid_at);
    }

    public function test_fake_driver_fails_for_numbers_ending_in_00(): void
    {
        config(['services.payments.driver' => 'fake', 'services.payments.fake_delay' => 0]);
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 100000]);
        Sanctum::actingAs($tenant);

        $id = $this->postJson('/api/payments', $this->body($rental, ['phone' => '0197000000']))->json('payment.id');

        $this->getJson("/api/payments/$id")->assertJsonPath('status', 'FAILED');
        $this->getJson('/api/me/rent')->assertJsonPath('paid', 0);
    }

    public function test_fake_driver_does_not_touch_settled_payment(): void
    {
        config(['services.payments.driver' => 'fake', 'services.payments.fake_delay' => 0]);
        [, $tenant, , $rental] = $this->activeSetup();
        Sanctum::actingAs($tenant);
        $p = $this->payment($rental, 1000, 'FAILED');

        $this->getJson("/api/payments/{$p->id}")->assertJsonPath('status', 'FAILED');
    }

    public function test_kkiapay_driver_never_self_settles(): void
    {
        config(['services.payments.driver' => 'kkiapay', 'services.payments.fake_delay' => 0]);
        [, $tenant, , $rental] = $this->activeSetup();
        Sanctum::actingAs($tenant);
        $p = $this->payment($rental, 1000, 'PENDING');

        $this->travel(1)->hours();
        $this->getJson("/api/payments/{$p->id}")->assertJsonPath('status', 'PENDING');
    }

    // ---- Consultation et reçu --------------------------------------------------------

    public function test_show_and_receipt_are_private(): void
    {
        [, , , $rental] = $this->activeSetup();
        $p = $this->payment($rental, 1000);
        $this->actingAsRole('TENANT');

        $this->getJson("/api/payments/{$p->id}")->assertForbidden();
        $this->getJson("/api/payments/{$p->id}/receipt")->assertForbidden();
    }

    public function test_show_unknown_payment_is_404(): void
    {
        $this->actingAsRole('TENANT');

        $this->getJson('/api/payments/'.fake()->uuid())->assertNotFound();
    }

    public function test_receipt_for_success_only(): void
    {
        [, $tenant, $housing, $rental] = $this->activeSetup(['title' => 'Villa Test']);
        Sanctum::actingAs($tenant);
        $ok = $this->payment($rental, 90000, 'SUCCESS');
        $pending = $this->payment($rental, 1000, 'PENDING');

        $this->getJson("/api/payments/{$ok->id}/receipt")->assertOk()
            ->assertJsonPath('amount', 90000)->assertJsonPath('housing', 'Villa Test')
            ->assertJsonPath('operator', 'MTN Mobile Money')->assertJsonPath('period', now()->format('Y-m'));
        $this->getJson("/api/payments/{$pending->id}/receipt")->assertStatus(400);
    }

    public function test_my_payments_lists_only_mine_latest_first_with_meta(): void
    {
        [, $tenant, , $rental] = $this->activeSetup();
        $other = $this->activeSetup()[3];
        Sanctum::actingAs($tenant);
        $this->payment($rental, 1000);
        $this->payment($rental, 2000);
        $this->payment($other, 9999);

        $this->getJson('/api/me/payments')->assertOk()
            ->assertJsonCount(2, 'data')->assertJsonPath('meta.total', 2)
            ->assertJsonStructure(['data' => [['id', 'amount', 'operator', 'paid_at', 'period', 'status']]]);
    }

    // ---- Webhook ---------------------------------------------------------------------

    private function pendingRef(): array
    {
        [, , , $rental] = $this->activeSetup();
        $p = $this->payment($rental, 1000, 'PENDING');

        return [$p, $p->reference];
    }

    public function test_webhook_approved_marks_success_with_provider_ref(): void
    {
        [$p, $ref] = $this->pendingRef();

        $this->postJson('/api/payments/webhook', ['reference' => $ref, 'status' => 'approved', 'transaction_id' => 'tx9'])
            ->assertOk()->assertJson(['received' => true]);

        $fresh = $p->fresh();
        $this->assertSame('SUCCESS', $fresh->status->value);
        $this->assertSame('tx9', $fresh->provider_ref);
        $this->assertNotNull($fresh->paid_at);
    }

    public function test_webhook_other_status_marks_failed(): void
    {
        [$p, $ref] = $this->pendingRef();

        $this->postJson('/api/payments/webhook', ['reference' => $ref, 'status' => 'declined'])->assertOk();

        $this->assertSame('FAILED', $p->fresh()->status->value);
    }

    public function test_webhook_is_idempotent_and_cannot_flip_a_success(): void
    {
        [$p, $ref] = $this->pendingRef();
        $this->postJson('/api/payments/webhook', ['reference' => $ref, 'status' => 'approved'])->assertOk();
        $this->postJson('/api/payments/webhook', ['reference' => $ref, 'status' => 'declined'])->assertOk();

        $this->assertSame('SUCCESS', $p->fresh()->status->value);
    }

    public function test_webhook_unknown_reference_is_acknowledged_without_effect(): void
    {
        $this->postJson('/api/payments/webhook', ['reference' => 'RC-NOPE', 'status' => 'approved'])->assertOk();
        $this->assertSame(0, Payment::count());
    }

    public function test_webhook_requires_secret_when_configured(): void
    {
        config(['services.kkiapay.secret' => 'abc']);
        [$p, $ref] = $this->pendingRef();

        $this->postJson('/api/payments/webhook', ['reference' => $ref, 'status' => 'approved'])->assertUnauthorized();
        $this->postJson('/api/payments/webhook', ['reference' => $ref, 'status' => 'approved'], ['x-kkiapay-secret' => 'nope'])->assertUnauthorized();
        $this->assertSame('PENDING', $p->fresh()->status->value);

        $this->postJson('/api/payments/webhook', ['reference' => $ref, 'status' => 'approved'], ['x-kkiapay-secret' => 'abc'])->assertOk();
        $this->assertSame('SUCCESS', $p->fresh()->status->value);
    }

    public function test_webhook_is_refused_in_production_without_secret(): void
    {
        config(['services.kkiapay.secret' => null]);
        $this->app['env'] = 'production';

        $this->postJson('/api/payments/webhook', ['reference' => 'x'])->assertStatus(503);
    }
}
