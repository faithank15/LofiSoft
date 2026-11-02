<?php

namespace Tests\Feature;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class UploadTest extends TestCase
{
    public function test_requires_auth(): void
    {
        $this->postJson('/api/uploads', [])->assertUnauthorized();
    }

    public function test_local_upload_stores_file_and_returns_public_url(): void
    {
        Storage::fake('public');
        config(['services.cloudinary.cloud_name' => null]);
        $this->actingAsRole('OWNER');

        $res = $this->post('/api/uploads', [
            'file' => UploadedFile::fake()->image('a.jpg'),
            'kind' => 'announcement_photo',
        ])->assertCreated();

        $this->assertStringContainsString('/storage/uploads/announcement_photo/', $res->json('url'));
        $this->assertCount(1, Storage::disk('public')->files('uploads/announcement_photo'));
    }

    /** @dataProvider invalid */
    public function test_validation(callable $file, string $kind, string $field): void
    {
        Storage::fake('public');
        $this->actingAsRole('OWNER');

        $this->post('/api/uploads', ['file' => $file(), 'kind' => $kind])->assertStatus(422)->assertJsonValidationErrors($field);
        $this->assertCount(0, Storage::disk('public')->allFiles());
    }

    public static function invalid(): array
    {
        return [
            'pas une image' => [fn () => UploadedFile::fake()->create('a.pdf', 10, 'application/pdf'), 'identity_id', 'file'],
            'gif refusé' => [fn () => UploadedFile::fake()->image('a.gif'), 'identity_id', 'file'],
            'trop lourd' => [fn () => UploadedFile::fake()->image('a.jpg')->size(9000), 'identity_id', 'file'],
            'kind inconnu' => [fn () => UploadedFile::fake()->image('a.jpg'), 'virus', 'kind'],
        ];
    }

    public function test_file_is_required(): void
    {
        $this->actingAsRole('OWNER');

        $this->postJson('/api/uploads', ['kind' => 'identity_id'])->assertStatus(422)->assertJsonValidationErrors('file');
    }

    public function test_cloudinary_upload_is_signed_and_returns_secure_url(): void
    {
        config(['services.cloudinary' => ['cloud_name' => 'demo', 'api_key' => 'k', 'api_secret' => 's']]);
        Http::fake(['api.cloudinary.com/*' => Http::response(['secure_url' => 'https://res.cloudinary.com/demo/x.jpg'], 200)]);
        $this->actingAsRole('OWNER');

        $this->post('/api/uploads', ['file' => UploadedFile::fake()->image('a.jpg'), 'kind' => 'identity_selfie'])
            ->assertCreated()->assertJsonPath('url', 'https://res.cloudinary.com/demo/x.jpg');

        Http::assertSent(function ($req) {
            $data = collect($req->data())->mapWithKeys(fn ($p) => [$p['name'] => $p['contents']]);

            return str_contains($req->url(), '/v1_1/demo/image/upload')
                && $data['api_key'] === 'k'
                && $data['folder'] === 'lofisoft/identity_selfie'
                && $data['signature'] === sha1("folder=lofisoft/identity_selfie&timestamp={$data['timestamp']}s");
        });
    }

    public function test_cloudinary_failure_gives_502_not_500(): void
    {
        config(['services.cloudinary' => ['cloud_name' => 'demo', 'api_key' => 'k', 'api_secret' => 's']]);
        Http::fake(['api.cloudinary.com/*' => Http::response(['error' => 'x'], 500)]);
        $this->actingAsRole('OWNER');

        $this->post('/api/uploads', ['file' => UploadedFile::fake()->image('a.jpg'), 'kind' => 'identity_id'])
            ->assertStatus(502)->assertJsonPath('message', 'Échec du téléversement vers Cloudinary.');
    }
}
