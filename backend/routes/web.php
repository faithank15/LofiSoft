<?php

use App\Http\Controllers\ResetPasswordController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

/**
 * Page de réinitialisation du mot de passe : cible du lien envoyé par e-mail.
 * Elle vit hors de l'API pour que le lien fonctionne depuis n'importe quel
 * navigateur, sans exiger une version récente de l'application.
 */
Route::get('/reset-password', [ResetPasswordController::class, 'show'])->name('password.reset');
Route::post('/reset-password', [ResetPasswordController::class, 'update'])->name('password.reset.update');
