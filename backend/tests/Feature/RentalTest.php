<?php

namespace Tests\Feature;

use App\Models\Rental;
use Tests\TestCase;

class RentalTest extends TestCase
{
    public function test_join_creates_pending_rental(): void
    {
        $housing = $this->housing($this->user('OWNER'), ['code' => 'K7F-29X']);
        $tenant = $this->actingAsRole('TENANT');

        $this->postJson('/api/rentals/join', ['code' => 'K7F-29X'])
            ->assertCreated()
            ->assertJsonPath('rental.status', 'PENDING');

        $this->assertDatabaseHas('rentals', ['tenant_id' => $tenant->id, 'housing_id' => $housing->id, 'status' => 'PENDING']);
    }

    public function test_join_accepts_lowercase_code(): void
    {
        $this->housing($this->user('OWNER'), ['code' => 'K7F-29X']);
        $this->actingAsRole('TENANT');

        $this->postJson('/api/rentals/join', ['code' => ' k7f-29x '])->assertCreated();
    }

    public function test_join_unknown_code_is_404_and_creates_nothing(): void
    {
        $this->actingAsRole('TENANT');

        $this->postJson('/api/rentals/join', ['code' => 'ZZZ-000'])->assertNotFound();
        $this->assertSame(0, Rental::count());
    }

    public function test_join_requires_code(): void
    {
        $this->actingAsRole('TENANT');

        $this->postJson('/api/rentals/join', [])->assertStatus(422)->assertJsonValidationErrors('code');
    }

    public function test_join_409_when_already_active_or_pending(): void
    {
        $housing = $this->housing($this->user('OWNER'), ['code' => 'K7F-29X']);
        $tenant = $this->actingAsRole('TENANT');
        $this->rental($housing, $tenant, 'PENDING');

        $this->postJson('/api/rentals/join', ['code' => 'K7F-29X'])->assertStatus(409);
        Rental::query()->update(['status' => 'ACTIVE']);
        $this->postJson('/api/rentals/join', ['code' => 'K7F-29X'])->assertStatus(409);
        $this->assertSame(1, Rental::count());
    }

    public function test_join_allowed_again_after_finished_rental(): void
    {
        $housing = $this->housing($this->user('OWNER'), ['code' => 'K7F-29X']);
        $tenant = $this->actingAsRole('TENANT');
        $this->rental($housing, $tenant, 'FINISHED');

        $this->postJson('/api/rentals/join', ['code' => 'K7F-29X'])->assertCreated();
    }

    public function test_join_refused_if_housing_already_has_an_active_tenant(): void
    {
        [, , $housing] = $this->activeSetup();
        $housing->update(['code' => 'M4T-83P']);
        $this->actingAsRole('TENANT');

        $this->postJson('/api/rentals/join', ['code' => 'M4T-83P'])->assertStatus(409);
    }

    public function test_owner_cannot_join(): void
    {
        $this->housing($this->user('OWNER'), ['code' => 'K7F-29X']);
        $this->actingAsRole('OWNER');

        $this->postJson('/api/rentals/join', ['code' => 'K7F-29X'])->assertForbidden();
    }

    public function test_me_rental_only_returns_active(): void
    {
        $housing = $this->housing($this->user('OWNER'));
        $tenant = $this->actingAsRole('TENANT');
        $this->rental($housing, $tenant, 'PENDING');

        $this->getJson('/api/me/rental')->assertNotFound();

        Rental::query()->update(['status' => 'ACTIVE']);
        $this->getJson('/api/me/rental')->assertOk()->assertJsonPath('data.status', 'ACTIVE');
    }

    public function test_end_rental_by_owner_only(): void
    {
        [$owner, , , $rental] = $this->activeSetup();
        $this->actingAsRole('OWNER');
        $this->postJson("/api/rentals/{$rental->id}/end")->assertForbidden();

        \Laravel\Sanctum\Sanctum::actingAs($owner);
        $this->postJson("/api/rentals/{$rental->id}/end")->assertOk();

        $fresh = $rental->fresh();
        $this->assertSame('FINISHED', $fresh->status->value);
        $this->assertNotNull($fresh->ended_at);
    }

    public function test_tenant_cannot_end_a_rental(): void
    {
        [, $tenant, , $rental] = $this->activeSetup();
        \Laravel\Sanctum\Sanctum::actingAs($tenant);

        $this->postJson("/api/rentals/{$rental->id}/end")->assertForbidden();
        $this->assertSame('ACTIVE', $rental->fresh()->status->value);
    }

    // ---- Loyer du mois ---------------------------------------------------------------

    public function test_rent_without_payment_is_upcoming_or_late_by_due_day(): void
    {
        [, $tenant] = $this->activeSetup(['rent' => 150000, 'due_day' => 28]);
        \Laravel\Sanctum\Sanctum::actingAs($tenant);

        $this->travelTo(now()->startOfMonth()->addDays(2));
        $this->getJson('/api/me/rent')->assertOk()
            ->assertJsonPath('status', 'UPCOMING')->assertJsonPath('total', 150000)
            ->assertJsonPath('paid', 0)->assertJsonPath('remaining', 150000);

        $this->travelTo(now()->startOfMonth()->addDays(28));
        $this->getJson('/api/me/rent')->assertJsonPath('status', 'LATE');
    }

    public function test_rent_partial_then_paid(): void
    {
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 150000]);
        \Laravel\Sanctum\Sanctum::actingAs($tenant);

        $this->payment($rental, 90000);
        $this->getJson('/api/me/rent')->assertJsonPath('status', 'PARTIAL')
            ->assertJsonPath('paid', 90000)->assertJsonPath('remaining', 60000);

        $this->payment($rental, 60000);
        $this->getJson('/api/me/rent')->assertJsonPath('status', 'PAID')->assertJsonPath('remaining', 0);
    }

    public function test_rent_ignores_pending_failed_and_other_periods(): void
    {
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 150000]);
        \Laravel\Sanctum\Sanctum::actingAs($tenant);

        $this->payment($rental, 50000, 'PENDING');
        $this->payment($rental, 50000, 'FAILED');
        $this->payment($rental, 150000, 'SUCCESS', now()->subMonth()->format('Y-m'));

        $this->getJson('/api/me/rent')->assertJsonPath('paid', 0);
    }

    public function test_rent_includes_carried_over(): void
    {
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 100000]);
        \Laravel\Sanctum\Sanctum::actingAs($tenant);
        $this->period($rental, now()->format('Y-m'), 100000, 40000);

        $this->getJson('/api/me/rent')->assertJsonPath('total', 140000)->assertJsonPath('remaining', 140000);
    }

    public function test_rent_never_negative_when_overpaid(): void
    {
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 100000]);
        \Laravel\Sanctum\Sanctum::actingAs($tenant);
        $this->payment($rental, 130000);

        $this->getJson('/api/me/rent')->assertJsonPath('remaining', 0)->assertJsonPath('status', 'PAID');
    }

    public function test_rent_404_without_active_rental_and_periods_empty(): void
    {
        $this->actingAsRole('TENANT');

        $this->getJson('/api/me/rent')->assertNotFound();
        $this->getJson('/api/me/rent/periods')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_rent_is_private_to_the_tenant(): void
    {
        [, , , $rental] = $this->activeSetup();
        $this->payment($rental, 100000);
        $this->actingAsRole('TENANT');

        $this->getJson('/api/me/rent')->assertNotFound();
    }

    public function test_periods_are_listed_latest_first(): void
    {
        [, $tenant, , $rental] = $this->activeSetup();
        \Laravel\Sanctum\Sanctum::actingAs($tenant);
        $this->period($rental, '2026-08', 100000);
        $this->period($rental, '2026-10', 100000);
        $this->period($rental, '2026-09', 100000);

        $this->getJson('/api/me/rent/periods')->assertOk()
            ->assertJsonPath('data.0.period', '2026-10')->assertJsonPath('data.2.period', '2026-08');
    }
}
