<?php

namespace Tests\Feature;

use App\Models\Payment;
use App\Models\Rental;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OwnerTest extends TestCase
{
    public function test_dashboard_aggregates_current_month(): void
    {
        [$owner, , , $rental] = $this->activeSetup(['rent' => 150000, 'due_day' => 1]);
        $this->housing($owner); // logement libre
        $this->payment($rental, 90000);
        $this->payment($rental, 5000, 'PENDING');
        $this->payment($rental, 7000, 'SUCCESS', now()->subMonth()->format('Y-m'));
        Sanctum::actingAs($owner);

        $this->travelTo(now()->startOfMonth()->addDays(10));
        $this->payment($rental, 0 + 1, 'FAILED');

        $this->getJson('/api/owner/dashboard')->assertOk()
            ->assertJsonPath('expected', 150000)
            ->assertJsonPath('received', 90000)
            ->assertJsonPath('late_count', 1)
            ->assertJsonPath('tenants_count', 1)
            ->assertJsonPath('housings_count', 2)
            ->assertJsonPath('month', now()->format('Y-m'));
    }

    public function test_requests_lists_only_pending_rentals_of_my_housings(): void
    {
        $owner = $this->user('OWNER');
        $housing = $this->housing($owner, ['title' => 'Studio']);
        $tenant = $this->user('TENANT', ['nom' => 'Agossa', 'prenoms' => 'Patrick', 'telephone' => '0197123456']);
        $pending = $this->rental($housing, $tenant, 'PENDING');

        // Pas dans la liste : location active, et demande sur le logement d'un autre.
        $this->rental($this->housing($owner), $this->user('TENANT'), 'ACTIVE');
        $this->rental($this->housing($this->user('OWNER')), $this->user('TENANT'), 'PENDING');

        Sanctum::actingAs($owner);
        $this->getJson('/api/owner/requests')->assertOk()->assertJsonCount(1)
            ->assertJsonPath('0.rental_id', (string) $pending->id)
            ->assertJsonPath('0.tenant_name', 'Patrick Agossa')
            ->assertJsonPath('0.tenant_phone', '0197123456')
            ->assertJsonPath('0.housing', 'Studio');
    }

    public function test_requests_is_for_owners_only(): void
    {
        $this->actingAsRole('TENANT');
        $this->getJson('/api/owner/requests')->assertForbidden();
    }

    public function test_accepting_a_request_makes_the_rental_active_and_empties_the_list(): void
    {
        $owner = $this->user('OWNER');
        $rental = $this->rental($this->housing($owner), $this->user('TENANT'), 'PENDING');
        Sanctum::actingAs($owner);

        $this->postJson("/api/owner/rentals/{$rental->id}/accept")->assertOk();

        $this->getJson('/api/owner/requests')->assertJsonCount(0);
        $this->getJson('/api/owner/tenants')->assertJsonCount(1);
    }

    public function test_dashboard_is_scoped_to_the_owner(): void
    {
        $this->activeSetup();
        $me = $this->actingAsRole('OWNER');

        $this->getJson('/api/owner/dashboard')->assertOk()
            ->assertJsonPath('expected', 0)->assertJsonPath('tenants_count', 0)->assertJsonPath('housings_count', 0);
    }

    public function test_late_count_ignores_fully_paid_tenants(): void
    {
        [$owner, , , $rental] = $this->activeSetup(['rent' => 100000, 'due_day' => 1]);
        $this->payment($rental, 100000);
        Sanctum::actingAs($owner);
        $this->travelTo(now()->startOfMonth()->addDays(10));

        $this->getJson('/api/owner/dashboard')->assertJsonPath('late_count', 0);
    }

    public function test_tenants_list_with_status_and_late_filter(): void
    {
        [$owner, , $housing, $r1] = $this->activeSetup(['title' => 'A', 'rent' => 100000, 'due_day' => 1]);
        $t2 = $this->user('TENANT');
        $h2 = $this->housing($owner, ['title' => 'B', 'rent' => 100000, 'due_day' => 1]);
        $r2 = $this->rental($h2, $t2);
        $this->payment($r2, 100000);
        Sanctum::actingAs($owner);
        $this->travelTo(now()->startOfMonth()->addDays(10));

        $all = collect($this->getJson('/api/owner/tenants')->assertOk()->json())->keyBy('housing');
        $this->assertSame('LATE', $all['A']['status']);
        $this->assertSame('PAID', $all['B']['status']);

        $this->getJson('/api/owner/tenants?status=LATE')->assertJsonCount(1)->assertJsonPath('0.housing', 'A');
    }

    public function test_tenants_excludes_pending_and_other_owners(): void
    {
        [$owner, , $housing] = $this->activeSetup();
        $this->rental($this->housing($owner), $this->user('TENANT'), 'PENDING');
        $this->activeSetup();
        Sanctum::actingAs($owner);

        $this->getJson('/api/owner/tenants')->assertOk()->assertJsonCount(1);
    }

    public function test_tenant_details_shows_payments_and_is_owner_scoped(): void
    {
        [$owner, , , $rental] = $this->activeSetup();
        $this->payment($rental, 1000);
        Sanctum::actingAs($owner);
        $this->getJson("/api/owner/tenants/{$rental->id}")->assertOk()->assertJsonCount(1, 'payments');

        $this->actingAsRole('OWNER');
        $this->getJson("/api/owner/tenants/{$rental->id}")->assertForbidden();
    }

    public function test_tenant_details_does_not_leak_tenant_password(): void
    {
        [$owner, , , $rental] = $this->activeSetup();
        Sanctum::actingAs($owner);

        $body = $this->getJson("/api/owner/tenants/{$rental->id}")->getContent();
        $this->assertStringNotContainsString('"password"', $body);
        $this->assertStringNotContainsString('remember_token', $body);
    }

    public function test_accept_pending_rental(): void
    {
        $owner = $this->user('OWNER');
        $rental = $this->rental($this->housing($owner), $this->user('TENANT'), 'PENDING');
        Sanctum::actingAs($owner);

        $this->postJson("/api/owner/rentals/{$rental->id}/accept")->assertOk();
        $this->assertSame('ACTIVE', $rental->fresh()->status->value);
    }

    public function test_accept_only_works_on_pending(): void
    {
        [$owner, , , $rental] = $this->activeSetup();
        $finished = $this->rental($this->housing($owner), $this->user('TENANT'), 'FINISHED');
        Sanctum::actingAs($owner);

        $this->postJson("/api/owner/rentals/{$finished->id}/accept")->assertStatus(409);
        $this->assertSame('FINISHED', $finished->fresh()->status->value);
    }

    public function test_accept_refused_if_housing_already_occupied(): void
    {
        [$owner, , $housing] = $this->activeSetup();
        $pending = $this->rental($housing, $this->user('TENANT'), 'PENDING');
        Sanctum::actingAs($owner);

        $this->postJson("/api/owner/rentals/{$pending->id}/accept")->assertStatus(409);
    }

    public function test_reject_pending_rental(): void
    {
        $owner = $this->user('OWNER');
        $rental = $this->rental($this->housing($owner), $this->user('TENANT'), 'PENDING');
        Sanctum::actingAs($owner);

        $this->postJson("/api/owner/rentals/{$rental->id}/reject")->assertOk();
        $this->assertNull(Rental::find($rental->id));
    }

    public function test_reject_cannot_erase_an_active_rental(): void
    {
        [$owner, , , $rental] = $this->activeSetup();
        Sanctum::actingAs($owner);

        $this->postJson("/api/owner/rentals/{$rental->id}/reject")->assertStatus(409);
        $this->assertNotNull(Rental::find($rental->id));
    }

    public function test_other_owner_cannot_accept_reject_or_remind(): void
    {
        $owner = $this->user('OWNER');
        $rental = $this->rental($this->housing($owner), $this->user('TENANT'), 'PENDING');
        $this->actingAsRole('OWNER');

        $this->postJson("/api/owner/rentals/{$rental->id}/accept")->assertForbidden();
        $this->postJson("/api/owner/rentals/{$rental->id}/reject")->assertForbidden();
        $this->postJson("/api/owner/rentals/{$rental->id}/remind")->assertForbidden();
        $this->assertSame('PENDING', $rental->fresh()->status->value);
    }

    public function test_remind_by_owner(): void
    {
        [$owner, , , $rental] = $this->activeSetup();
        Sanctum::actingAs($owner);

        $this->postJson("/api/owner/rentals/{$rental->id}/remind")->assertOk();
    }

    public function test_manual_payment_records_cash_success(): void
    {
        [$owner, , , $rental] = $this->activeSetup(['rent' => 100000]);
        Sanctum::actingAs($owner);

        $this->postJson('/api/owner/payments/manual', ['rental_id' => $rental->id, 'period' => now()->format('Y-m'), 'amount' => 40000, 'note' => 'Main à main'])
            ->assertCreated();

        $p = Payment::first();
        $this->assertSame('CASH', $p->operator->value);
        $this->assertSame('SUCCESS', $p->status->value);
        $this->assertStringStartsWith('CASH-', $p->reference);

        Sanctum::actingAs($rental->tenant);
        $this->getJson('/api/me/rent')->assertJsonPath('paid', 40000)->assertJsonPath('status', 'PARTIAL');
    }

    public function test_manual_payment_cannot_exceed_balance(): void
    {
        [$owner, , , $rental] = $this->activeSetup(['rent' => 100000]);
        $this->payment($rental, 80000);
        Sanctum::actingAs($owner);

        $this->postJson('/api/owner/payments/manual', ['rental_id' => $rental->id, 'period' => now()->format('Y-m'), 'amount' => 20001])
            ->assertStatus(422)->assertJsonValidationErrors('amount');
    }

    public function test_manual_payment_validation_and_ownership(): void
    {
        [$owner, , , $rental] = $this->activeSetup();
        Sanctum::actingAs($owner);
        $this->postJson('/api/owner/payments/manual', ['rental_id' => $rental->id, 'period' => 'x', 'amount' => 0])
            ->assertStatus(422)->assertJsonValidationErrors(['period', 'amount']);

        $this->actingAsRole('OWNER');
        $this->postJson('/api/owner/payments/manual', ['rental_id' => $rental->id, 'period' => now()->format('Y-m'), 'amount' => 1000])->assertForbidden();
        $this->assertSame(0, Payment::count());
    }

    public function test_owner_space_is_closed_to_tenants_and_anonymous(): void
    {
        $this->getJson('/api/owner/dashboard')->assertUnauthorized();
        $this->actingAsRole('TENANT');
        $this->getJson('/api/owner/dashboard')->assertForbidden();
        $this->getJson('/api/owner/tenants')->assertForbidden();
        $this->postJson('/api/owner/payments/manual', [])->assertForbidden();
    }
}
