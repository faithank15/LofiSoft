<?php

namespace Tests\Support;

use App\Models\Announcement;
use App\Models\Housing;
use App\Models\Payment;
use App\Models\Rental;
use App\Models\RentPeriod;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

/** Fabriques de données minimalistes partagées par les tests d'API. */
trait BuildsData
{
    protected function user(string $role = 'TENANT', array $attrs = []): User
    {
        return User::factory()->create(['role' => $role] + $attrs);
    }

    protected function actingAsRole(string $role = 'TENANT', array $attrs = []): User
    {
        $user = $this->user($role, $attrs);
        Sanctum::actingAs($user);

        return $user;
    }

    protected function housing(User $owner, array $attrs = []): Housing
    {
        return Housing::create($attrs + [
            'owner_id' => $owner->id,
            'title' => 'Appartement test',
            'type' => 'HOUSE',
            'rent' => 100000,
            'due_day' => 5,
            'city' => 'Cotonou',
            'district' => 'Fidjrossè',
        ]);
    }

    protected function rental(Housing $housing, User $tenant, string $status = 'ACTIVE'): Rental
    {
        return Rental::create([
            'housing_id' => $housing->id,
            'tenant_id' => $tenant->id,
            'status' => $status,
            'started_at' => now()->subMonths(2)->toDateString(),
        ]);
    }

    protected function announcement(User $owner, array $attrs = []): Announcement
    {
        return Announcement::create($attrs + [
            'owner_id' => $owner->id,
            'title' => 'Chambre test',
            'type' => 'ROOM',
            'rent' => 50000,
            'deposit_months' => 2,
            'city' => 'Cotonou',
            'district' => 'Akpakpa',
            'rooms' => 1,
            'status' => 'PUBLISHED',
            'published_at' => now(),
        ]);
    }

    protected function payment(Rental $rental, int $amount, string $status = 'SUCCESS', ?string $period = null): Payment
    {
        return Payment::create([
            'rental_id' => $rental->id,
            'period' => $period ?? now()->format('Y-m'),
            'amount' => $amount,
            'operator' => 'MTN',
            'phone' => '0197000011',
            'status' => $status,
            'reference' => 'T-'.uniqid(),
            'paid_at' => $status === 'SUCCESS' ? now() : null,
        ]);
    }

    protected function period(Rental $rental, string $period, int $total, int $carried = 0): RentPeriod
    {
        return RentPeriod::create([
            'rental_id' => $rental->id,
            'period' => $period,
            'total' => $total,
            'carried_over' => $carried,
            'due_date' => $period.'-05',
        ]);
    }

    /** Un locataire avec une location ACTIVE dans le logement d'un propriétaire. */
    protected function activeSetup(array $housingAttrs = []): array
    {
        $owner = $this->user('OWNER', ['identity_verified' => true]);
        $tenant = $this->user('TENANT');
        $housing = $this->housing($owner, $housingAttrs);
        $rental = $this->rental($housing, $tenant);

        return [$owner, $tenant, $housing, $rental];
    }
}
