<?php

namespace Tests\Feature;

use App\Models\RentPeriod;
use Illuminate\Console\Scheduling\Schedule;
use Tests\TestCase;

class RolloverCommandTest extends TestCase
{
    public function test_opens_period_with_housing_rent_and_due_date(): void
    {
        [, , , $rental] = $this->activeSetup(['rent' => 120000, 'due_day' => 7]);

        $this->artisan('rent:rollover', ['--month' => '2026-11'])->expectsOutput('1 période(s) ouverte(s) pour 2026-11.')->assertSuccessful();

        $p = RentPeriod::where('rental_id', $rental->id)->first();
        $this->assertSame(120000, $p->total);
        $this->assertSame(0, $p->carried_over);
        $this->assertSame('2026-11-07', $p->due_date->toDateString());
    }

    public function test_carries_over_unpaid_balance(): void
    {
        [, , , $rental] = $this->activeSetup(['rent' => 100000]);
        $this->period($rental, '2026-10', 100000, 20000);
        $this->payment($rental, 90000, 'SUCCESS', '2026-10');
        $this->payment($rental, 50000, 'PENDING', '2026-10');
        $this->payment($rental, 50000, 'FAILED', '2026-10');

        $this->artisan('rent:rollover', ['--month' => '2026-11']);

        $this->assertSame(30000, RentPeriod::where('period', '2026-11')->value('carried_over'));
    }

    public function test_nothing_carried_when_fully_paid_or_overpaid(): void
    {
        [, , , $rental] = $this->activeSetup(['rent' => 100000]);
        $this->period($rental, '2026-10', 100000);
        $this->payment($rental, 130000, 'SUCCESS', '2026-10');

        $this->artisan('rent:rollover', ['--month' => '2026-11']);

        $this->assertSame(0, RentPeriod::where('period', '2026-11')->value('carried_over'));
    }

    public function test_is_idempotent(): void
    {
        $this->activeSetup();

        $this->artisan('rent:rollover', ['--month' => '2026-11']);
        $this->artisan('rent:rollover', ['--month' => '2026-11'])->expectsOutput('0 période(s) ouverte(s) pour 2026-11.');

        $this->assertSame(1, RentPeriod::count());
    }

    public function test_ignores_pending_and_finished_rentals(): void
    {
        [$owner] = $this->activeSetup();
        $this->rental($this->housing($owner), $this->user('TENANT'), 'PENDING');
        $this->rental($this->housing($owner), $this->user('TENANT'), 'FINISHED');

        $this->artisan('rent:rollover', ['--month' => '2026-11']);

        $this->assertSame(1, RentPeriod::count());
    }

    public function test_does_not_carry_over_a_gap_month(): void
    {
        [, , , $rental] = $this->activeSetup(['rent' => 100000]);
        $this->period($rental, '2026-08', 100000);

        $this->artisan('rent:rollover', ['--month' => '2026-11']);

        $this->assertSame(0, RentPeriod::where('period', '2026-11')->value('carried_over'));
    }

    public function test_defaults_to_current_month(): void
    {
        $this->activeSetup();

        $this->artisan('rent:rollover')->assertSuccessful();

        $this->assertSame(now()->format('Y-m'), RentPeriod::first()->period);
    }

    public function test_period_feeds_the_tenant_rent_endpoint(): void
    {
        [, $tenant, , $rental] = $this->activeSetup(['rent' => 100000]);
        $this->period($rental, now()->subMonth()->format('Y-m'), 100000);
        $this->artisan('rent:rollover');
        \Laravel\Sanctum\Sanctum::actingAs($tenant);

        $this->getJson('/api/me/rent')->assertJsonPath('total', 200000);
    }

    public function test_is_scheduled_monthly_on_the_first(): void
    {
        $event = collect(app(Schedule::class)->events())->first(fn ($e) => str_contains($e->command, 'rent:rollover'));

        $this->assertNotNull($event);
        $this->assertSame('5 0 1 * *', $event->expression);
    }
}
