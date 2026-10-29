<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ImageStorage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

class UploadController extends Controller
{
    public function store(Request $request, ImageStorage $storage): JsonResponse
    {
        $validated = $request->validate([
            'file' => ['required', 'file', 'image', 'mimes:jpeg,png,jpg', 'max:8192'],
            'kind' => ['required', 'string', 'in:announcement_photo,identity_id,identity_selfie'],
        ]);

        try {
            $url = $storage->store($request->file('file'), $validated['kind']);
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], Response::HTTP_BAD_GATEWAY);
        }

        return response()->json(['url' => $url], Response::HTTP_CREATED);
    }
}
