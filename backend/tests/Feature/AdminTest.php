<?php

namespace Tests\Feature;

use App\Models\IdentityRequest;
use App\Models\Report;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminTest extends TestCase
{
    private function identity(array $over = []): IdentityRequest
    {
        return IdentityRequest::create($over + [
            'owner_id' => $this->user('OWNER')->id,
            'id_image_url' => 'https://x.test/id.jpg',
            'selfie_url' => 'https://x.test/s.jpg',
            'status' => 'PENDING',
        ]);
    }

    public function test_every_admin_route_is_closed_to_non_admins(): void
    {
        $this->getJson('/api/admin/users')->assertUnauthorized();

        foreach (['TENANT', 'OWNER'] as $role) {
            $this->actingAsRole($role);
            $id = fake()->uuid();
            $this->getJson('/api/admin/identity-requests')->assertForbidden();
            $this->postJson("/api/admin/identity-requests/$id/approve")->assertForbidden();
            $this->postJson("/api/admin/identity-requests/$id/reject", ['reason' => 'x'])->assertForbidden();
            $this->getJson('/api/admin/reports')->assertForbidden();
            $this->postJson("/api/admin/reports/$id/resolve", ['action' => 'WARN_OWNER'])->assertForbidden();
            $this->postJson("/api/admin/reports/$id/dismiss")->assertForbidden();
            $this->getJson('/api/admin/users')->assertForbidden();
            $this->putJson("/api/admin/users/$id/active", ['actif' => false])->assertForbidden();
        }
    }

    public function test_identity_requests_default_to_pending_and_filter(): void
    {
        $this->identity();
        $this->identity(['status' => 'APPROVED']);
        $this->actingAsRole('ADMIN');

        $this->getJson('/api/admin/identity-requests')->assertOk()->assertJsonCount(1)
            ->assertJsonStructure([['id', 'owner' => ['id', 'name'], 'id_image_url', 'selfie_url', 'status', 'created_at']]);
        $this->getJson('/api/admin/identity-requests?status=APPROVED')->assertJsonCount(1);
    }

    public function test_approve_verifies_the_owner(): void
    {
        $req = $this->identity();
        $admin = $this->actingAsRole('ADMIN');

        $this->postJson("/api/admin/identity-requests/{$req->id}/approve")->assertOk();

        $this->assertSame('APPROVED', $req->fresh()->status->value);
        $this->assertSame($admin->id, $req->fresh()->reviewed_by);
        $this->assertTrue($req->owner->fresh()->identity_verified);
    }

    public function test_verified_badge_shows_up_in_public_feed_after_approval(): void
    {
        $req = $this->identity();
        $this->announcement($req->owner);
        $this->getJson('/api/announcements')->assertJsonPath('data.0.verified', false);

        Sanctum::actingAs($this->user('ADMIN'));
        $this->postJson("/api/admin/identity-requests/{$req->id}/approve")->assertOk();

        $this->getJson('/api/announcements')->assertJsonPath('data.0.verified', true);
    }

    public function test_reject_requires_reason_and_keeps_owner_unverified(): void
    {
        $req = $this->identity();
        $this->actingAsRole('ADMIN');

        $this->postJson("/api/admin/identity-requests/{$req->id}/reject", [])->assertStatus(422)->assertJsonValidationErrors('reason');
        $this->postJson("/api/admin/identity-requests/{$req->id}/reject", ['reason' => 'Photo floue'])->assertOk();

        $this->assertSame('REJECTED', $req->fresh()->status->value);
        $this->assertSame('Photo floue', $req->fresh()->reason);
        $this->assertFalse($req->owner->fresh()->identity_verified);
    }

    public function test_a_decided_request_cannot_be_decided_again(): void
    {
        $req = $this->identity(['status' => 'REJECTED']);
        $this->actingAsRole('ADMIN');

        $this->postJson("/api/admin/identity-requests/{$req->id}/approve")->assertStatus(409);
        $this->assertFalse($req->owner->fresh()->identity_verified);
    }

    private function report(array $over = []): Report
    {
        $a = $over['announcement'] ?? $this->announcement($this->user('OWNER'));
        unset($over['announcement']);

        return Report::create($over + [
            'announcement_id' => $a->id,
            'reporter_id' => $this->user('TENANT')->id,
            'reason' => 'Arnaque',
            'status' => 'PENDING',
        ]);
    }

    public function test_reports_list_with_count_per_announcement(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $this->report(['announcement' => $a]);
        $this->report(['announcement' => $a]);
        $this->report(['status' => 'RESOLVED']);
        $this->actingAsRole('ADMIN');

        $this->getJson('/api/admin/reports')->assertOk()->assertJsonCount(2)
            ->assertJsonPath('0.reports_count', 2)
            ->assertJsonStructure([['id', 'reason', 'details', 'status', 'created_at', 'announcement' => ['id', 'title'], 'reports_count']]);
    }

    public function test_resolve_remove_cancels_the_announcement(): void
    {
        $r = $this->report();
        $this->actingAsRole('ADMIN');

        $this->postJson("/api/admin/reports/{$r->id}/resolve", ['action' => 'REMOVE_ANNOUNCEMENT'])->assertOk();

        $this->assertSame('RESOLVED', $r->fresh()->status->value);
        $this->assertSame('CANCELED', $r->announcement->fresh()->status->value);
        $this->getJson('/api/announcements')->assertJsonCount(0, 'data');
    }

    public function test_resolve_warn_keeps_the_announcement(): void
    {
        $r = $this->report();
        $this->actingAsRole('ADMIN');

        $this->postJson("/api/admin/reports/{$r->id}/resolve", ['action' => 'WARN_OWNER'])->assertOk();

        $this->assertSame('PUBLISHED', $r->announcement->fresh()->status->value);
    }

    public function test_resolve_validates_action_and_dismiss_works(): void
    {
        $r = $this->report();
        $this->actingAsRole('ADMIN');

        $this->postJson("/api/admin/reports/{$r->id}/resolve", ['action' => 'EXPLODE'])->assertStatus(422);
        $this->postJson("/api/admin/reports/{$r->id}/dismiss")->assertOk();
        $this->assertSame('DISMISSED', $r->fresh()->status->value);
    }

    public function test_users_list_filters_and_never_exposes_secrets(): void
    {
        $this->user('TENANT', ['nom' => 'Zinsou']);
        $this->user('OWNER', ['nom' => 'Mensah']);
        $this->actingAsRole('ADMIN');

        $this->getJson('/api/admin/users?role=OWNER')->assertJsonCount(1, 'data.data');
        $this->getJson('/api/admin/users?q=Zinsou')->assertJsonCount(1, 'data.data');

        $body = $this->getJson('/api/admin/users')->getContent();
        $this->assertStringNotContainsString('"password"', $body);
        $this->assertStringNotContainsString('remember_token', $body);
    }

    public function test_toggle_user_active_blocks_login_and_existing_token(): void
    {
        $u = $this->user('TENANT', ['email' => 'a@lofi.bj']);
        $token = $u->createToken('t')->plainTextToken;
        Sanctum::actingAs($this->user('ADMIN'));

        $this->putJson("/api/admin/users/{$u->id}/active", ['actif' => false])->assertOk();
        $this->assertFalse($u->fresh()->actif);

        $this->postJson('/api/auth/login', ['email' => 'a@lofi.bj', 'password' => 'Test1234'])->assertForbidden();

        $this->putJson("/api/admin/users/{$u->id}/active", ['actif' => true])->assertOk();
        $this->postJson('/api/auth/login', ['email' => 'a@lofi.bj', 'password' => 'Test1234'])->assertOk();
    }

    public function test_toggle_requires_boolean_and_admin_cannot_suspend_self(): void
    {
        $admin = $this->actingAsRole('ADMIN');
        $u = $this->user('TENANT');

        $this->putJson("/api/admin/users/{$u->id}/active", ['actif' => 'peut-être'])->assertStatus(422);
        $this->putJson("/api/admin/users/{$admin->id}/active", ['actif' => false])->assertStatus(422);
        $this->assertTrue($admin->fresh()->actif);
    }
}
