<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class UploadController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'file' => ['required', 'file', 'image', 'mimes:jpeg,png,jpg', 'max:8192'],
            'kind' => ['required', 'string', 'in:announcement_photo,identity_id,identity_selfie'],
        ]);

        $file = $request->file('file');
        $filename = uniqid('lofi_', true) . '.' . $file->getClientOriginalExtension();
        $path = $file->storeAs('uploads/' . $validated['kind'], $filename, 'public');

        $url = asset('storage/' . $path);

        return response()->json(['url' => $url], Response::HTTP_CREATED);
    }
}
