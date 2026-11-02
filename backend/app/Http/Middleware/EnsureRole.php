<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    private const MESSAGES = [
        'OWNER' => 'Action réservée aux propriétaires.',
        'TENANT' => 'Action réservée aux locataires.',
        'ADMIN' => 'Accès réservé aux administrateurs.',
    ];

    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $role = $request->user()?->role->value;

        if (! in_array($role, $roles, true)) {
            return response()->json([
                'message' => self::MESSAGES[$roles[0]] ?? 'Accès non autorisé.',
            ], Response::HTTP_FORBIDDEN);
        }

        return $next($request);
    }
}
