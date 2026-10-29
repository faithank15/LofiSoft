<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterRequest;
use App\Models\IdentityRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Symfony\Component\HttpFoundation\Response;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = User::create([
            'nom' => $validated['nom'],
            'prenoms' => $validated['prenoms'],
            'email' => strtolower($validated['email']),
            'telephone' => $validated['telephone'],
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'],
            'actif' => true,
            'identity_verified' => false,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => [
                'id' => (string) $user->id,
                'nom' => $user->nom,
                'prenoms' => $user->prenoms,
                'email' => $user->email,
                'telephone' => $user->telephone,
                'role' => $user->role->value,
                'actif' => (bool) $user->actif,
            ],
        ], Response::HTTP_CREATED);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', strtolower($validated['email']))->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'message' => 'Email ou mot de passe incorrect.',
            ], Response::HTTP_UNAUTHORIZED);
        }

        if (! $user->actif) {
            return response()->json([
                'message' => 'Ce compte a été suspendu.',
            ], Response::HTTP_FORBIDDEN);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => [
                'id' => (string) $user->id,
                'nom' => $user->nom,
                'prenoms' => $user->prenoms,
                'email' => $user->email,
                'telephone' => $user->telephone,
                'role' => $user->role->value,
                'actif' => (bool) $user->actif,
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'user' => [
                'id' => (string) $user->id,
                'nom' => $user->nom,
                'prenoms' => $user->prenoms,
                'email' => $user->email,
                'telephone' => $user->telephone,
                'role' => $user->role->value,
                'actif' => (bool) $user->actif,
            ],
        ]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate(['email' => ['required', 'email']]);

        return response()->json([
            'message' => 'Si cette adresse existe, un lien de réinitialisation a été envoyé.',
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(null, Response::HTTP_NO_CONTENT);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nom' => ['sometimes', 'string', 'max:100'],
            'prenoms' => ['sometimes', 'string', 'max:100'],
            'telephone' => ['sometimes', 'string', 'regex:/^01[0-9]{8}$/'],
        ]);

        $user = $request->user();
        $user->update($validated);

        return response()->json([
            'user' => [
                'id' => (string) $user->id,
                'nom' => $user->nom,
                'prenoms' => $user->prenoms,
                'email' => $user->email,
                'telephone' => $user->telephone,
                'role' => $user->role->value,
                'actif' => (bool) $user->actif,
            ],
        ]);
    }

    public function updatePassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $user = $request->user();

        if (! Hash::check($validated['current_password'], $user->password)) {
            return response()->json([
                'message' => 'Le mot de passe actuel est incorrect.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $user->update(['password' => Hash::make($validated['password'])]);

        return response()->json([
            'message' => 'Mot de passe modifié avec succès.',
        ]);
    }

    public function submitIdentity(Request $request): JsonResponse
    {
        if ($request->user()->role->value !== 'OWNER') {
            return response()->json(['message' => 'Action réservée aux propriétaires.'], Response::HTTP_FORBIDDEN);
        }

        $validated = $request->validate([
            'id_image_url' => ['required', 'url'],
            'selfie_url' => ['required', 'url'],
        ]);

        $identityRequest = IdentityRequest::create([
            'owner_id' => $request->user()->id,
            'id_image_url' => $validated['id_image_url'],
            'selfie_url' => $validated['selfie_url'],
            'status' => 'PENDING',
        ]);

        return response()->json([
            'id' => (string) $identityRequest->id,
            'status' => 'PENDING',
            'message' => 'Documents soumis pour vérification.',
        ], Response::HTTP_CREATED);
    }
}
