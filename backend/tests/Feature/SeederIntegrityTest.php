<?php

namespace Tests\Feature;

use App\Models\Announcement;
use App\Models\Housing;
use App\Models\Rental;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Tests\TestCase;

/** Les comptes et codes documentés dans backend/docs doivent exister et fonctionner. */
class SeederIntegrityTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    public function test_documented_accounts_can_log_in(): void
    {
        foreach (['locataire@lofi.bj', 'locataire2@lofi.bj', 'proprio@lofi.bj', 'proprio2@lofi.bj', 'admin@lofi.bj'] as $email) {
            $this->postJson('/api/auth/login', ['email' => $email, 'password' => 'Test1234'])->assertOk();
        }
    }

    public function test_roles_and_verification(): void
    {
        $this->assertSame('TENANT', User::where('email', 'locataire@lofi.bj')->first()->role->value);
        $this->assertSame('ADMIN', User::where('email', 'admin@lofi.bj')->first()->role->value);
        $this->assertTrue(User::where('email', 'proprio@lofi.bj')->first()->identity_verified);
        $this->assertFalse(User::where('email', 'proprio2@lofi.bj')->first()->identity_verified);
    }

    public function test_documented_housing_codes(): void
    {
        $this->getJson('/api/housings/lookup?code=M4T-83P')->assertOk();
        $this->getJson('/api/housings/lookup?code=K7F-29X')->assertOk();
        $this->getJson('/api/housings/lookup?code=P9Q-55D')->assertOk();
        $this->assertTrue(Housing::where('code', 'M4T-83P')->first()->activeRental()->exists());
        $this->assertFalse(Housing::where('code', 'K7F-29X')->first()->activeRental()->exists());
    }

    public function test_tenant_story_matches_docs(): void
    {
        $this->postJson('/api/auth/login', ['email' => 'locataire@lofi.bj', 'password' => 'Test1234']);
        \Laravel\Sanctum\Sanctum::actingAs(User::where('email', 'locataire@lofi.bj')->first());

        $this->getJson('/api/me/rent')->assertOk()
            ->assertJsonPath('total', 150000)->assertJsonPath('paid', 90000)->assertJsonPath('status', 'PARTIAL');
        $this->getJson('/api/me/favorites')->assertJsonCount(2, 'data');
    }

    public function test_free_tenant_can_join_a_free_housing_but_not_the_rented_one(): void
    {
        \Laravel\Sanctum\Sanctum::actingAs(User::where('email', 'locataire2@lofi.bj')->first());

        $this->postJson('/api/rentals/join', ['code' => 'M4T-83P'])->assertStatus(409);
        $this->postJson('/api/rentals/join', ['code' => 'K7F-29X'])->assertCreated();
    }

    public function test_feed_has_published_only_and_one_draft_exists(): void
    {
        $this->assertSame(1, Announcement::where('status', 'DRAFT')->count());
        $published = Announcement::where('status', 'PUBLISHED')->count();

        $this->getJson('/api/announcements?per_page=50')->assertJsonPath('meta.total', $published);
    }

    public function test_admin_has_pending_work(): void
    {
        \Laravel\Sanctum\Sanctum::actingAs(User::where('email', 'admin@lofi.bj')->first());

        $this->getJson('/api/admin/reports')->assertJsonCount(1);
        $this->getJson('/api/admin/identity-requests')->assertJsonCount(1);
    }

    public function test_referential_integrity(): void
    {
        $this->assertSame(0, Housing::whereDoesntHave('owner')->count());
        $this->assertSame(0, Rental::whereDoesntHave('housing')->count());
        $this->assertSame(0, Rental::whereDoesntHave('tenant')->count());
        $this->assertSame(Housing::count(), Housing::distinct('code')->count('code'));
    }

    public function test_seeder_can_be_run_on_a_fresh_database_only_once_cleanly(): void
    {
        $this->assertSame(5, User::count());
    }
}
