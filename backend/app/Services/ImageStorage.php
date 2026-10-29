<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Stocke une image et renvoie son URL publique.
 * Cloudinary si CLOUDINARY_* est renseigné, disque local `public` sinon (dev).
 */
class ImageStorage
{
    public function store(UploadedFile $file, string $kind): string
    {
        return $this->usesCloudinary()
            ? $this->toCloudinary($file, $kind)
            : $this->toLocalDisk($file, $kind);
    }

    private function usesCloudinary(): bool
    {
        return filled(config('services.cloudinary.cloud_name'))
            && filled(config('services.cloudinary.api_key'))
            && filled(config('services.cloudinary.api_secret'));
    }

    private function toCloudinary(UploadedFile $file, string $kind): string
    {
        $cfg = config('services.cloudinary');
        $params = [
            'folder' => 'lofisoft/'.$kind,
            'timestamp' => time(),
        ];

        ksort($params);
        $toSign = urldecode(http_build_query($params));
        $signature = sha1($toSign.$cfg['api_secret']);

        $response = Http::asMultipart()
            ->attach('file', $file->get(), $file->getClientOriginalName())
            ->post("https://api.cloudinary.com/v1_1/{$cfg['cloud_name']}/image/upload", [
                ['name' => 'api_key', 'contents' => $cfg['api_key']],
                ['name' => 'timestamp', 'contents' => (string) $params['timestamp']],
                ['name' => 'folder', 'contents' => $params['folder']],
                ['name' => 'signature', 'contents' => $signature],
            ]);

        if ($response->failed() || ! $response->json('secure_url')) {
            throw new RuntimeException('Échec du téléversement vers Cloudinary.');
        }

        return $response->json('secure_url');
    }

    private function toLocalDisk(UploadedFile $file, string $kind): string
    {
        $filename = uniqid('lofi_', true).'.'.$file->getClientOriginalExtension();
        $path = $file->storeAs('uploads/'.$kind, $filename, 'public');

        return asset('storage/'.$path);
    }
}
