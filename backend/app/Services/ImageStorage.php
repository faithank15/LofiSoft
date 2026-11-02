<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Throwable;

/**
 * Stocke une image et renvoie son URL publique.
 * Cloudinary si CLOUDINARY_URL est renseigné, disque local `public` sinon (dev).
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
        return filled(config('cloudinary.cloud_url'));
    }

    private function toCloudinary(UploadedFile $file, string $kind): string
    {
        try {
            return app(CloudinaryService::class)->upload($file, $kind)['url'];
        } catch (Throwable $e) {
            Log::warning('Échec Cloudinary : '.$e->getMessage());

            throw new RuntimeException('Échec du téléversement vers Cloudinary.', 0, $e);
        }
    }

    private function toLocalDisk(UploadedFile $file, string $kind): string
    {
        $filename = uniqid('lofi_', true).'.'.$file->getClientOriginalExtension();
        $path = $file->storeAs('uploads/'.$kind, $filename, 'public');

        return asset('storage/'.$path);
    }
}
