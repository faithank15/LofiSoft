<?php

namespace Tests\Feature;

use App\Models\Announcement;
use Tests\TestCase;

class AnnouncementTest extends TestCase
{
    private function body(array $over = []): array
    {
        return $over + [
            'title' => 'Belle chambre',
            'type' => 'ROOM',
            'rent' => 45000,
            'deposit_months' => 2,
            'city' => 'Cotonou',
            'district' => 'Akpakpa',
            'rooms' => 1,
        ];
    }

    // ---- Fil public ------------------------------------------------------------------

    public function test_feed_is_public_and_lists_only_published(): void
    {
        $owner = $this->user('OWNER');
        $this->announcement($owner, ['title' => 'Publiée']);
        $this->announcement($owner, ['title' => 'Brouillon', 'status' => 'DRAFT']);
        $this->announcement($owner, ['title' => 'Annulée', 'status' => 'CANCELED']);

        $this->getJson('/api/announcements')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Publiée')
            ->assertJsonStructure(['meta' => ['current_page', 'last_page', 'total']]);
    }

    public function test_feed_item_has_contract_fields(): void
    {
        $this->announcement($this->user('OWNER', ['identity_verified' => true]));

        $this->getJson('/api/announcements')->assertJsonStructure(['data' => [[
            'id', 'title', 'type', 'rent', 'deposit_months', 'city', 'district',
            'rooms', 'photos', 'verified', 'is_favorite', 'status', 'published_at',
        ]]])->assertJsonPath('data.0.verified', true)->assertJsonPath('data.0.is_favorite', false);
    }

    public function test_feed_filters(): void
    {
        $o = $this->user('OWNER');
        $this->announcement($o, ['title' => 'A', 'city' => 'Cotonou', 'type' => 'ROOM', 'rent' => 30000]);
        $this->announcement($o, ['title' => 'B', 'city' => 'Abomey-Calavi', 'type' => 'HOUSE', 'rent' => 120000]);
        $this->announcement($o, ['title' => 'C', 'city' => 'Cotonou', 'type' => 'HOUSE', 'rent' => 200000, 'district' => 'Haie Vive']);

        $titles = fn (string $qs) => collect($this->getJson('/api/announcements?'.$qs)->assertOk()->json('data'))->pluck('title')->sort()->values()->all();

        $this->assertSame(['A', 'C'], $titles('city=Cotonou'));
        $this->assertSame(['B', 'C'], $titles('type=HOUSE'));
        $this->assertSame(['B', 'C'], $titles('min_price=100000'));
        $this->assertSame(['A', 'B'], $titles('max_price=150000'));
        $this->assertSame(['B'], $titles('min_price=100000&max_price=150000'));
        $this->assertSame(['C'], $titles('q=Haie'));
        $this->assertSame(['C'], $titles('city=Cotonou&type=HOUSE'));
        $this->assertSame([], $titles('city=Parakou'));
    }

    public function test_feed_pagination(): void
    {
        $o = $this->user('OWNER');
        foreach (range(1, 5) as $i) {
            $this->announcement($o, ['title' => "N$i"]);
        }

        $this->getJson('/api/announcements?per_page=2&page=3')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('meta.last_page', 3)
            ->assertJsonPath('meta.total', 5);
    }

    public function test_feed_caps_per_page(): void
    {
        $o = $this->user('OWNER');
        foreach (range(1, 3) as $i) {
            $this->announcement($o);
        }

        $this->getJson('/api/announcements?per_page=100000')->assertOk()->assertJsonPath('meta.last_page', 1);
        $this->getJson('/api/announcements?per_page=0')->assertOk();
        $this->getJson('/api/announcements?per_page=-5')->assertOk();
    }

    public function test_feed_like_wildcards_in_search_are_not_special(): void
    {
        $this->announcement($this->user('OWNER'), ['title' => 'Villa']);

        $this->getJson('/api/announcements?q=%25')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_feed_marks_favorites_for_tenant_only(): void
    {
        $owner = $this->user('OWNER');
        $a = $this->announcement($owner);
        $tenant = $this->actingAsRole('TENANT');
        $tenant->favorites()->attach($a->id);

        $this->getJson('/api/announcements')->assertJsonPath('data.0.is_favorite', true);
    }

    // ---- Détail ----------------------------------------------------------------------

    public function test_show_returns_description_and_owner(): void
    {
        $owner = $this->user('OWNER', ['prenoms' => 'Koffi', 'nom' => 'Mensah']);
        $a = $this->announcement($owner, ['description' => 'Calme']);

        $this->getJson("/api/announcements/{$a->id}")
            ->assertOk()
            ->assertJsonPath('description', 'Calme')
            ->assertJsonPath('owner.name', 'Koffi Mensah')
            ->assertJsonPath('owner.id', (string) $owner->id);
    }

    public function test_show_unknown_id_is_404_json(): void
    {
        $this->getJson('/api/announcements/'.fake()->uuid())->assertNotFound()->assertJsonPath('message', 'Ressource introuvable.');
    }

    public function test_draft_and_canceled_are_hidden_from_public_and_other_users(): void
    {
        $owner = $this->user('OWNER');
        $draft = $this->announcement($owner, ['status' => 'DRAFT']);
        $canceled = $this->announcement($owner, ['status' => 'CANCELED']);

        $this->getJson("/api/announcements/{$draft->id}")->assertNotFound();
        $this->getJson("/api/announcements/{$canceled->id}")->assertNotFound();

        $this->actingAsRole('TENANT');
        $this->getJson("/api/announcements/{$draft->id}")->assertNotFound();
    }

    public function test_owner_can_still_see_own_draft(): void
    {
        $owner = $this->actingAsRole('OWNER');
        $draft = $this->announcement($owner, ['status' => 'DRAFT']);

        $this->getJson("/api/announcements/{$draft->id}")->assertOk();
    }

    // ---- Création / édition ----------------------------------------------------------

    public function test_store_creates_draft_with_photos_in_order(): void
    {
        $owner = $this->actingAsRole('OWNER');

        $this->postJson('/api/announcements', $this->body(['photos' => ['https://x.test/1.jpg', 'https://x.test/2.jpg']]))
            ->assertCreated()
            ->assertJsonPath('status', 'DRAFT')
            ->assertJsonPath('photos', ['https://x.test/1.jpg', 'https://x.test/2.jpg']);

        $this->assertDatabaseHas('announcements', ['owner_id' => $owner->id, 'status' => 'DRAFT']);
    }

    /** @dataProvider invalidBodies */
    public function test_store_validation(array $over, string $field): void
    {
        $this->actingAsRole('OWNER');

        $this->postJson('/api/announcements', $this->body($over))->assertStatus(422)->assertJsonValidationErrors($field);
        $this->assertSame(0, Announcement::count());
    }

    public static function invalidBodies(): array
    {
        return [
            'titre vide' => [['title' => ''], 'title'],
            'type inconnu' => [['type' => 'CHATEAU'], 'type'],
            'loyer trop bas' => [['rent' => 999], 'rent'],
            'loyer texte' => [['rent' => 'cher'], 'rent'],
            'caution négative' => [['deposit_months' => -1], 'deposit_months'],
            'ville vide' => [['city' => ''], 'city'],
            'pièces zéro' => [['rooms' => 0], 'rooms'],
            'photo pas url' => [['photos' => ['abc']], 'photos.0'],
            'trop de photos' => [['photos' => array_fill(0, 11, 'https://x.test/a.jpg')], 'photos'],
        ];
    }

    public function test_store_refuses_housing_of_another_owner(): void
    {
        $this->actingAsRole('OWNER');
        $other = $this->user('OWNER');
        $foreign = $this->housing($other);

        $this->postJson('/api/announcements', $this->body(['housing_id' => $foreign->id]))
            ->assertStatus(422)->assertJsonValidationErrors('housing_id');
    }

    public function test_update_by_owner(): void
    {
        $owner = $this->actingAsRole('OWNER');
        $a = $this->announcement($owner);

        $this->putJson("/api/announcements/{$a->id}", ['title' => 'Nouveau', 'rent' => 60000])
            ->assertOk()->assertJsonPath('title', 'Nouveau')->assertJsonPath('rent', 60000);
    }

    public function test_update_cannot_change_owner_or_status(): void
    {
        $owner = $this->actingAsRole('OWNER');
        $other = $this->user('OWNER');
        $a = $this->announcement($owner, ['status' => 'DRAFT']);

        $this->putJson("/api/announcements/{$a->id}", ['owner_id' => $other->id, 'status' => 'PUBLISHED'])->assertOk();

        $fresh = $a->fresh();
        $this->assertSame($owner->id, $fresh->owner_id);
        $this->assertSame('DRAFT', $fresh->status->value);
    }

    public function test_update_validates(): void
    {
        $owner = $this->actingAsRole('OWNER');
        $a = $this->announcement($owner);

        $this->putJson("/api/announcements/{$a->id}", ['rent' => 5])->assertStatus(422);
        $this->putJson("/api/announcements/{$a->id}", ['rooms' => 0])->assertStatus(422);
        $this->putJson("/api/announcements/{$a->id}", ['deposit_months' => -2])->assertStatus(422);
    }

    public function test_other_owner_cannot_update_publish_or_cancel(): void
    {
        $a = $this->announcement($this->user('OWNER'), ['status' => 'DRAFT']);
        $this->actingAsRole('OWNER');

        $this->putJson("/api/announcements/{$a->id}", ['title' => 'Piraté'])->assertForbidden();
        $this->postJson("/api/announcements/{$a->id}/publish")->assertForbidden();
        $this->postJson("/api/announcements/{$a->id}/cancel")->assertForbidden();
        $this->assertSame('DRAFT', $a->fresh()->status->value);
    }

    public function test_publish_sets_status_and_date(): void
    {
        $owner = $this->actingAsRole('OWNER');
        $a = $this->announcement($owner, ['status' => 'DRAFT', 'published_at' => null]);

        $this->postJson("/api/announcements/{$a->id}/publish")->assertOk();

        $fresh = $a->fresh();
        $this->assertSame('PUBLISHED', $fresh->status->value);
        $this->assertNotNull($fresh->published_at);
        $this->getJson('/api/announcements')->assertJsonCount(1, 'data');
    }

    public function test_cancelled_announcement_cannot_be_republished(): void
    {
        $owner = $this->actingAsRole('OWNER');
        $a = $this->announcement($owner, ['status' => 'CANCELED']);

        $this->postJson("/api/announcements/{$a->id}/publish")->assertStatus(409);
        $this->assertSame('CANCELED', $a->fresh()->status->value);
    }

    public function test_cancel_removes_from_feed(): void
    {
        $owner = $this->actingAsRole('OWNER');
        $a = $this->announcement($owner);

        $this->postJson("/api/announcements/{$a->id}/cancel")->assertOk();
        $this->getJson('/api/announcements')->assertJsonCount(0, 'data');
    }

    public function test_my_announcements_lists_own_including_drafts_only(): void
    {
        $me = $this->actingAsRole('OWNER');
        $this->announcement($me, ['status' => 'DRAFT']);
        $this->announcement($me);
        $this->announcement($this->user('OWNER'));

        $this->getJson('/api/me/announcements')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_tenant_cannot_manage_announcements(): void
    {
        $a = $this->announcement($this->user('OWNER'));
        $this->actingAsRole('TENANT');

        $this->postJson('/api/announcements', $this->body())->assertForbidden();
        $this->putJson("/api/announcements/{$a->id}", ['title' => 'x'])->assertForbidden();
        $this->getJson('/api/me/announcements')->assertForbidden();
    }

    public function test_anonymous_cannot_write(): void
    {
        $this->postJson('/api/announcements', $this->body())->assertUnauthorized();
        $this->getJson('/api/me/announcements')->assertUnauthorized();
        $this->getJson('/api/me/favorites')->assertUnauthorized();
    }
}
