<?php

use App\Http\Middleware\EnsureActiveAccount;
use App\Http\Middleware\EnsureRole;
use Illuminate\Contracts\Auth\Middleware\AuthenticatesRequests;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias(['role' => EnsureRole::class]);
        $middleware->api(append: [EnsureActiveAccount::class]);
        // Vérifier le rôle avant de résoudre les modèles : pas de 404/403 qui révèle l'existence d'un id.
        $middleware->appendToPriorityList(after: AuthenticatesRequests::class, append: EnsureRole::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Contrat d'API : toute erreur de /api est { "message": "..." } en français.
        $exceptions->render(fn (NotFoundHttpException $e, Request $request) => $request->is('api/*')
            ? response()->json(['message' => 'Ressource introuvable.'], 404)
            : null);
        $exceptions->render(fn (AccessDeniedHttpException $e, Request $request) => $request->is('api/*')
            ? response()->json(['message' => 'Accès non autorisé.'], 403)
            : null);
        $exceptions->render(fn (AuthenticationException $e, Request $request) => $request->is('api/*')
            ? response()->json(['message' => 'Authentification requise.'], 401)
            : null);
    })->create();
