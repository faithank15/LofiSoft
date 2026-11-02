<?php

namespace Tests\Unit;

use App\Enums\AccommodationType;
use App\Enums\AnnouncementStatus;
use App\Enums\IdentityStatus;
use App\Enums\Operator;
use App\Enums\PaymentStatus;
use App\Enums\RentalStatus;
use App\Enums\RentStatus;
use App\Enums\ReportStatus;
use App\Enums\UserRole;
use App\Models\Housing;
use App\Models\User;
use App\Services\RentBalance;
use Tests\TestCase;

class DomainTest extends TestCase
{
    /** Les valeurs d'enum sont le contrat JSON avec le mobile : on les fige. */
    public function test_enum_values_match_api_contract(): void
    {
        $this->assertSame(['TENANT', 'OWNER', 'ADMIN'], array_column(UserRole::cases(), 'value'));
        $this->assertSame(['HOUSE', 'ROOM', 'OTHER'], array_column(AccommodationType::cases(), 'value'));
        $this->assertSame(['PENDING', 'ACTIVE', 'FINISHED'], array_column(RentalStatus::cases(), 'value'));
        $this->assertSame(['PAID', 'PARTIAL', 'LATE', 'UPCOMING'], array_column(RentStatus::cases(), 'value'));
        $this->assertSame(['PENDING', 'SUCCESS', 'FAILED'], array_column(PaymentStatus::cases(), 'value'));
        $this->assertEqualsCanonicalizing(['MTN', 'MOOV', 'CASH'], array_column(Operator::cases(), 'value'));
        $this->assertEqualsCanonicalizing(['PENDING', 'APPROVED', 'REJECTED'], array_column(IdentityStatus::cases(), 'value'));
        $this->assertContains('PUBLISHED', array_column(AnnouncementStatus::cases(), 'value'));
        $this->assertContains('DRAFT', array_column(AnnouncementStatus::cases(), 'value'));
        $this->assertContains('CANCELED', array_column(AnnouncementStatus::cases(), 'value'));
        $this->assertEqualsCanonicalizing(['PENDING', 'RESOLVED', 'DISMISSED'], array_column(ReportStatus::cases(), 'value'));
    }

    public function test_generated_housing_code_format(): void
    {
        for ($i = 0; $i < 30; $i++) {
            $this->assertMatchesRegularExpression('/^[A-Z0-9]{3}-[A-Z0-9]{3}$/', Housing::generateUniqueCode());
        }
    }

    public function test_generated_code_skips_existing_ones(): void
    {
        $owner = $this->user('OWNER');
        $this->housing($owner, ['code' => 'AAA-111']);

        $this->assertNotSame('AAA-111', Housing::generateUniqueCode());
    }

    public function test_user_hides_password_and_token_in_serialization(): void
    {
        $array = $this->user()->toArray();

        $this->assertArrayNotHasKey('password', $array);
        $this->assertArrayNotHasKey('remember_token', $array);
    }

    public function test_user_casts(): void
    {
        $u = $this->user('OWNER', ['identity_verified' => 1, 'actif' => 0])->fresh();

        $this->assertSame(UserRole::OWNER, $u->role);
        $this->assertTrue($u->identity_verified);
        $this->assertFalse($u->actif);
    }

    public function test_user_password_is_hashed_on_assignment(): void
    {
        $u = User::factory()->create(['password' => 'clair-12345']);

        $this->assertNotSame('clair-12345', $u->password);
    }

    public function test_rent_balance_math(): void
    {
        [, , $housing, $rental] = $this->activeSetup(['rent' => 100000]);
        $svc = new RentBalance();
        $period = now()->format('Y-m');

        $this->assertSame(100000, $svc->due($rental->load('housing'), $period));
        $this->assertSame(100000, $svc->remaining($rental, $period));

        $this->period($rental, $period, 100000, 25000);
        $this->payment($rental, 60000);
        $this->payment($rental, 99999, 'PENDING');
        $this->payment($rental, 99999, 'FAILED');

        $this->assertSame(125000, $svc->due($rental, $period));
        $this->assertSame(60000, $svc->paid($rental, $period));
        $this->assertSame(65000, $svc->remaining($rental, $period));
    }

    public function test_rent_balance_is_per_period_and_never_negative(): void
    {
        [, , , $rental] = $this->activeSetup(['rent' => 100000]);
        $svc = new RentBalance();
        $this->payment($rental, 150000, 'SUCCESS', '2026-01');

        $this->assertSame(0, $svc->remaining($rental->load('housing'), '2026-01'));
        $this->assertSame(100000, $svc->remaining($rental, '2026-02'));
    }

    public function test_rental_active_relation_ignores_pending(): void
    {
        $owner = $this->user('OWNER');
        $housing = $this->housing($owner);
        $this->rental($housing, $this->user(), 'PENDING');
        $this->assertFalse($housing->activeRental()->exists());

        $this->rental($housing, $this->user(), 'ACTIVE');
        $this->assertTrue($housing->activeRental()->exists());
    }
}
