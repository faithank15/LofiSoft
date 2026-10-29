<?php

namespace Tests\Feature;

use Tests\TestCase;

class FavoriteAndReportTest extends TestCase
{
    public function test_add_and_list_favorites(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $this->actingAsRole('TENANT');

        $this->putJson("/api/announcements/{$a->id}/favorite")->assertOk();

        $this->getJson('/api/me/favorites')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', (string) $a->id);
    }

    public function test_adding_favorite_twice_is_idempotent(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $tenant = $this->actingAsRole('TENANT');

        $this->putJson("/api/announcements/{$a->id}/favorite")->assertOk();
        $this->putJson("/api/announcements/{$a->id}/favorite")->assertOk();

        $this->assertSame(1, $tenant->favorites()->count());
    }

    public function test_remove_favorite(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $tenant = $this->actingAsRole('TENANT');
        $tenant->favorites()->attach($a->id);

        $this->deleteJson("/api/announcements/{$a->id}/favorite")->assertNoContent();
        $this->assertSame(0, $tenant->favorites()->count());
    }

    public function test_removing_absent_favorite_is_harmless(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $this->actingAsRole('TENANT');

        $this->deleteJson("/api/announcements/{$a->id}/favorite")->assertNoContent();
    }

    public function test_favorites_are_private_per_user(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $one = $this->user('TENANT');
        $one->favorites()->attach($a->id);

        $this->actingAsRole('TENANT');
        $this->getJson('/api/me/favorites')->assertJsonCount(0, 'data');
    }

    public function test_favorite_unknown_announcement_is_404(): void
    {
        $this->actingAsRole('TENANT');

        $this->putJson('/api/announcements/'.fake()->uuid().'/favorite')->assertNotFound();
    }

    public function test_cannot_favorite_a_draft(): void
    {
        $draft = $this->announcement($this->user('OWNER'), ['status' => 'DRAFT']);
        $this->actingAsRole('TENANT');

        $this->putJson("/api/announcements/{$draft->id}/favorite")->assertNotFound();
    }

    public function test_report_creates_pending_report(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $tenant = $this->actingAsRole('TENANT');

        $this->postJson("/api/announcements/{$a->id}/reports", ['reason' => 'Arnaque', 'details' => 'Faux prix'])
            ->assertCreated();

        $this->assertDatabaseHas('reports', ['announcement_id' => $a->id, 'reporter_id' => $tenant->id, 'status' => 'PENDING']);
    }

    public function test_report_requires_reason_and_limits_length(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $this->actingAsRole('TENANT');

        $this->postJson("/api/announcements/{$a->id}/reports", [])->assertStatus(422)->assertJsonValidationErrors('reason');
        $this->postJson("/api/announcements/{$a->id}/reports", ['reason' => str_repeat('x', 201)])->assertStatus(422);
    }

    public function test_same_user_cannot_report_same_announcement_twice(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $this->actingAsRole('TENANT');

        $this->postJson("/api/announcements/{$a->id}/reports", ['reason' => 'Arnaque'])->assertCreated();
        $this->postJson("/api/announcements/{$a->id}/reports", ['reason' => 'Arnaque'])->assertStatus(409);
        $this->assertDatabaseCount('reports', 1);
    }

    public function test_report_requires_auth(): void
    {
        $a = $this->announcement($this->user('OWNER'));

        $this->postJson("/api/announcements/{$a->id}/reports", ['reason' => 'x'])->assertUnauthorized();
    }
}
