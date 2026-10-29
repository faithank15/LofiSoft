<?php

namespace Tests\Feature;

use App\Models\Housing;
use Tests\TestCase;

class HousingTest extends TestCase
{
    private function body(array $over = []): array
    {
        return $over + ['title' => 'Villa', 'type' => 'HOUSE', 'rent' => 200000, 'due_day' => 5, 'city' => 'Cotonou', 'district' => 'Haie Vive'];
    }

    public function test_store_generates_unique_code_in_expected_format(): void
    {
        $owner = $this->actingAsRole('OWNER');

        $res = $this->postJson('/api/housings', $this->body())->assertCreated();

        $this->assertMatchesRegularExpression('/^[A-Z0-9]{3}-[A-Z0-9]{3}$/', $res->json('data.code'));
        $this->assertSame($owner->id, Housing::first()->owner_id);
    }

    public function test_codes_are_unique_across_many_housings(): void
    {
        $owner = $this->user('OWNER');
        foreach (range(1, 60) as $_) {
            $this->housing($owner);
        }

        $this->assertSame(60, Housing::distinct('code')->count('code'));
    }

    /** @dataProvider invalid */
    public function test_store_validation(array $over, string $field): void
    {
        $this->actingAsRole('OWNER');

        $this->postJson('/api/housings', $this->body($over))->assertStatus(422)->assertJsonValidationErrors($field);
    }

    public static function invalid(): array
    {
        return [
            'jour 0' => [['due_day' => 0], 'due_day'],
            'jour 29' => [['due_day' => 29], 'due_day'],
            'loyer bas' => [['rent' => 500], 'rent'],
            'type' => [['type' => 'X'], 'type'],
            'titre' => [['title' => ''], 'title'],
        ];
    }

    public function test_due_day_boundaries_are_accepted(): void
    {
        $this->actingAsRole('OWNER');

        $this->postJson('/api/housings', $this->body(['due_day' => 1]))->assertCreated();
        $this->postJson('/api/housings', $this->body(['due_day' => 28]))->assertCreated();
    }

    public function test_client_cannot_choose_code_or_owner(): void
    {
        $me = $this->actingAsRole('OWNER');
        $other = $this->user('OWNER');

        $res = $this->postJson('/api/housings', $this->body(['code' => 'AAA-111', 'owner_id' => $other->id]))->assertCreated();

        $this->assertNotSame('AAA-111', $res->json('data.code'));
        $this->assertSame($me->id, Housing::first()->owner_id);
    }

    public function test_index_lists_only_own_housings(): void
    {
        $me = $this->actingAsRole('OWNER');
        $this->housing($me);
        $this->housing($this->user('OWNER'));

        $this->getJson('/api/housings')->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_show_and_update_are_owner_scoped(): void
    {
        $mine = $this->housing($me = $this->actingAsRole('OWNER'));
        $theirs = $this->housing($this->user('OWNER'));

        $this->getJson("/api/housings/{$mine->id}")->assertOk();
        $this->getJson("/api/housings/{$theirs->id}")->assertForbidden();
        $this->putJson("/api/housings/{$mine->id}", ['rent' => 120000])->assertOk()->assertJsonPath('data.rent', 120000);
        $this->putJson("/api/housings/{$theirs->id}", ['rent' => 1])->assertForbidden();
        $this->assertSame(100000, $theirs->fresh()->rent);
    }

    public function test_update_cannot_change_code(): void
    {
        $h = $this->housing($this->actingAsRole('OWNER'), ['code' => 'AAA-111']);

        $this->putJson("/api/housings/{$h->id}", ['code' => 'ZZZ-999', 'owner_id' => $this->user('OWNER')->id])->assertOk();

        $this->assertSame('AAA-111', $h->fresh()->code);
    }

    public function test_tenant_cannot_manage_housings(): void
    {
        $this->actingAsRole('TENANT');

        $this->postJson('/api/housings', $this->body())->assertForbidden();
        $this->getJson('/api/housings')->assertForbidden();
    }

    // ---- Lookup par code -------------------------------------------------------------

    public function test_lookup_is_public_and_returns_preview(): void
    {
        $owner = $this->user('OWNER', ['prenoms' => 'Koffi', 'nom' => 'Mensah', 'identity_verified' => true]);
        $this->housing($owner, ['code' => 'M4T-83P', 'rent' => 150000, 'due_day' => 5]);

        $this->getJson('/api/housings/lookup?code=M4T-83P')
            ->assertOk()
            ->assertJsonPath('housing.rent', 150000)
            ->assertJsonPath('housing.due_day', 5)
            ->assertJsonPath('housing.owner_verified', true)
            ->assertJsonPath('housing.owner_name', 'Koffi Mensah')
            ->assertJsonStructure(['housing' => ['id', 'title', 'city', 'district']]);
    }

    public function test_lookup_normalises_case_and_spaces(): void
    {
        $this->housing($this->user('OWNER'), ['code' => 'M4T-83P']);

        $this->getJson('/api/housings/lookup?code=%20m4t-83p%20')->assertOk();
    }

    public function test_lookup_unknown_or_missing_code_is_404(): void
    {
        $this->getJson('/api/housings/lookup?code=ZZZ-000')->assertNotFound()
            ->assertJsonPath('message', 'Ce code ne correspond à aucun logement.');
        $this->getJson('/api/housings/lookup')->assertNotFound();
    }

    public function test_lookup_does_not_leak_private_owner_data(): void
    {
        $owner = $this->user('OWNER', ['email' => 'secret@lofi.bj', 'telephone' => '0197555555']);
        $this->housing($owner, ['code' => 'M4T-83P']);

        $body = $this->getJson('/api/housings/lookup?code=M4T-83P')->getContent();

        $this->assertStringNotContainsString('secret@lofi.bj', $body);
        $this->assertStringNotContainsString('0197555555', $body);
    }
}
