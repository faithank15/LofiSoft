<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Housing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class HousingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $housings = Housing::with('activeRental.tenant')
            ->where('owner_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json(['data' => $housings]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:150'],
            'type' => ['required', 'string', 'in:HOUSE,ROOM,OTHER'],
            'rent' => ['required', 'integer', 'min:1000'],
            'due_day' => ['required', 'integer', 'between:1,28'],
            'city' => ['required', 'string', 'max:100'],
            'district' => ['required', 'string', 'max:100'],
            'photos' => ['nullable', 'array'],
        ]);

        $housing = $request->user()->housings()->create($validated);

        return response()->json(['data' => $housing], Response::HTTP_CREATED);
    }

    public function show(Request $request, Housing $housing): JsonResponse
    {
        if ($housing->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        return response()->json(['data' => $housing->load('activeRental.tenant')]);
    }

    public function update(Request $request, Housing $housing): JsonResponse
    {
        if ($housing->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Accès non autorisé.'], Response::HTTP_FORBIDDEN);
        }

        $validated = $request->validate([
            'rent' => ['sometimes', 'integer', 'min:1000'],
            'due_day' => ['sometimes', 'integer', 'between:1,28'],
            'city' => ['sometimes', 'string'],
            'district' => ['sometimes', 'string'],
            'title' => ['sometimes', 'string'],
        ]);

        $housing->update($validated);

        return response()->json(['data' => $housing]);
    }

    public function lookup(Request $request): JsonResponse
    {
        $code = strtoupper(trim((string) $request->query('code')));

        $housing = Housing::with('owner')->where('code', $code)->first();

        if (! $housing) {
            return response()->json([
                'message' => 'Ce code ne correspond à aucun logement.',
            ], Response::HTTP_NOT_FOUND);
        }

        return response()->json([
            'housing' => [
                'id' => (string) $housing->id,
                'title' => $housing->title,
                'city' => $housing->city,
                'district' => $housing->district,
                'rent' => (int) $housing->rent,
                'due_day' => (int) $housing->due_day,
                'owner_verified' => (bool) ($housing->owner?->identity_verified ?? false),
                'owner_name' => trim(($housing->owner?->prenoms ?? '') . ' ' . ($housing->owner?->nom ?? '')),
            ],
        ]);
    }
}
