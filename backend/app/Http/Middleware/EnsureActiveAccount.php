<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Un compte suspendu perd l'accès immédiatement (401 : le mobile efface alors sa session). */
class EnsureActiveAccount
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user('sanctum');

        if ($user && ! $user->actif) {
            return response()->json(['message' => 'Ce compte a été suspendu.'], Response::HTTP_UNAUTHORIZED);
        }

        return $next($request);
    }
}
