<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Password;
use Illuminate\View\View;

/**
 * Page web de réinitialisation du mot de passe (cible du lien reçu par e-mail).
 *
 * Elle est volontairement hors de l'API : l'utilisateur choisit son nouveau
 * mot de passe dans son navigateur, ce qui fonctionne même avec une version
 * ancienne de l'application installée.
 */
class ResetPasswordController extends Controller
{
    public function show(Request $request): View
    {
        return view('auth.reset-password', [
            'token' => (string) $request->query('token', ''),
            'email' => (string) $request->query('email', ''),
            'error' => null,
            'success' => null,
        ]);
    }

    public function update(Request $request): View
    {
        $validated = $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $status = Password::reset(
            [
                'token' => $validated['token'],
                'email' => strtolower($validated['email']),
                'password' => $validated['password'],
            ],
            function (User $user, string $password): void {
                // Le cast 'hashed' du modèle hashe tout seul : on assigne le mot
                // de passe en clair, jamais un hash pré-calculé.
                $user->password = $password;
                $user->save();

                // Les jetons d'API existants tombent : un mot de passe réinitialisé
                // doit invalider les sessions ouvertes avec l'ancien.
                $user->tokens()->delete();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return view('auth.reset-password', [
                'token' => $validated['token'],
                'email' => $validated['email'],
                'error' => 'Ce lien est invalide ou a expiré. Demandez-en un nouveau.',
                'success' => null,
            ]);
        }

        return view('auth.reset-password', [
            'token' => '',
            'email' => $validated['email'],
            'error' => null,
            'success' => 'Mot de passe modifié. Vous pouvez maintenant vous connecter à l\'application.',
        ]);
    }
}
