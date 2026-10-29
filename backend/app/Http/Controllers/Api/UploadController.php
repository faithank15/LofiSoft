<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\CloudinaryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class UploadController extends Controller
{
    /**
     * POST /api/uploads
     * Champs : file (image jpeg/png), kind (announcement_photo | identity_id | identity_selfie)
     * Réponse : { "url": "https://res.cloudinary.com/..." }
     */
    public function store(Request $request, CloudinaryService $cloudinary): JsonResponse
    {
        $validated = $request->validate([
            'file' => ['required', 'file', 'image', 'mimes:jpeg,png,jpg', 'max:' . config('cloudinary.max_size_kb')],
            'kind' => ['required', 'string', 'in:announcement_photo,identity_id,identity_selfie'],
        ]);

        try {
            $uploaded = $cloudinary->upload($request->file('file'), $validated['kind']);
        } catch (Throwable $e) {
            Log::error("Échec de l'envoi vers Cloudinary", [
                'kind' => $validated['kind'],
                'error' => $e->getMessage(),
            ]);

            return response()->json(
                ['message' => "Impossible d'envoyer l'image pour le moment. Réessaie dans un instant."],
                Response::HTTP_BAD_GATEWAY
            );
        }

        return response()->json(['url' => $uploaded['url']], Response::HTTP_CREATED);
    }
}
