<?php

namespace App\Services;

use Cloudinary\Cloudinary;
use Illuminate\Http\UploadedFile;
use RuntimeException;

class CloudinaryService
{
    private Cloudinary $cloudinary;

    public function __construct()
    {
        $cloudUrl = config('cloudinary.cloud_url');

        if (empty($cloudUrl)) {
            throw new RuntimeException('CLOUDINARY_URL est manquant dans le fichier .env');
        }

        $this->cloudinary = new Cloudinary($cloudUrl);
    }

    /**
     * Envoie une image sur Cloudinary.
     *
     * @return array{url: string, public_id: string}
     */
    public function upload(UploadedFile $file, ?string $subfolder = null): array
    {
        $folder = trim(config('cloudinary.folder') . '/' . ($subfolder ?? ''), '/');

        $result = $this->cloudinary->uploadApi()->upload($file->getRealPath(), [
            'folder' => $folder,
            'resource_type' => 'image',
        ]);

        return [
            'url' => $result['secure_url'],
            'public_id' => $result['public_id'],
        ];
    }

    /**
     * Supprime une image de Cloudinary à partir de son public_id.
     */
    public function delete(string $publicId): void
    {
        $this->cloudinary->uploadApi()->destroy($publicId, [
            'resource_type' => 'image',
        ]);
    }

    /**
     * Vérifie que le public_id appartient bien au dossier racine de l'application.
     */
    public function belongsToApp(string $publicId): bool
    {
        return str_starts_with($publicId, trim(config('cloudinary.folder'), '/') . '/');
    }
}
