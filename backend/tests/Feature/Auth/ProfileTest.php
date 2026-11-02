<?php

namespace Tests\Feature\Auth;

use App\Models\IdentityRequest;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    public function test_update_profile_changes_only_given_fields(): void
    {
        $user = $this->actingAsRole('TENANT', ['nom' => 'Ancien']);

        $this->putJson('/api/me', ['prenoms' => 'Nouveau'])
            ->assertOk()
            ->assertJsonPath('user.prenoms', 'Nouveau')
            ->assertJsonPath('user.nom', 'Ancien');

        $this->assertSame('Nouveau', $user->fresh()->prenoms);
    }

    public function test_update_profile_cannot_change_role_email_or_flags(): void
    {
        $user = $this->actingAsRole('TENANT', ['email' => 'a@lofi.bj']);

        $this->putJson('/api/me', ['role' => 'ADMIN', 'email' => 'b@lofi.bj', 'identity_verified' => true, 'actif' => false])
            ->assertOk();

        $fresh = $user->fresh();
        $this->assertSame('TENANT', $fresh->role->value);
        $this->assertSame('a@lofi.bj', $fresh->email);
        $this->assertFalse($fresh->identity_verified);
        $this->assertTrue($fresh->actif);
    }

    public function test_update_profile_validates_phone(): void
    {
        $this->actingAsRole();

        $this->putJson('/api/me', ['telephone' => '12345'])->assertStatus(422)->assertJsonValidationErrors('telephone');
    }

    public function test_update_profile_requires_auth(): void
    {
        $this->putJson('/api/me', ['nom' => 'X'])->assertUnauthorized();
    }

    public function test_update_password_success_then_new_password_logs_in(): void
    {
        $this->actingAsRole('TENANT', ['email' => 'a@lofi.bj']);

        $this->putJson('/api/me/password', ['current_password' => 'Test1234', 'password' => 'Nouveau123'])
            ->assertOk();

        $this->postJson('/api/auth/login', ['email' => 'a@lofi.bj', 'password' => 'Nouveau123'])->assertOk();
        $this->postJson('/api/auth/login', ['email' => 'a@lofi.bj', 'password' => 'Test1234'])->assertUnauthorized();
    }

    public function test_update_password_rejects_wrong_current_password(): void
    {
        $this->actingAsRole();

        $this->putJson('/api/me/password', ['current_password' => 'faux', 'password' => 'Nouveau123'])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Le mot de passe actuel est incorrect.');
    }

    public function test_update_password_enforces_minimum_length(): void
    {
        $this->actingAsRole();

        $this->putJson('/api/me/password', ['current_password' => 'Test1234', 'password' => 'court'])
            ->assertStatus(422)->assertJsonValidationErrors('password');
    }

    public function test_submit_identity_creates_pending_request(): void
    {
        $owner = $this->actingAsRole('OWNER');

        $this->postJson('/api/me/identity', ['id_image_url' => 'https://x.test/id.jpg', 'selfie_url' => 'https://x.test/s.jpg'])
            ->assertCreated()
            ->assertJsonPath('status', 'PENDING');

        $this->assertDatabaseHas('identity_requests', ['owner_id' => $owner->id, 'status' => 'PENDING']);
    }

    public function test_submit_identity_validates_urls(): void
    {
        $this->actingAsRole('OWNER');

        $this->postJson('/api/me/identity', ['id_image_url' => 'pas-une-url', 'selfie_url' => ''])
            ->assertStatus(422)->assertJsonValidationErrors(['id_image_url', 'selfie_url']);
        $this->assertSame(0, IdentityRequest::count());
    }

    public function test_submit_identity_is_owner_only(): void
    {
        $this->actingAsRole('TENANT');

        $this->postJson('/api/me/identity', ['id_image_url' => 'https://x.test/a', 'selfie_url' => 'https://x.test/b'])
            ->assertForbidden();
    }
}
