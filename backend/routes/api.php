<?php

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\HousingController;
use App\Http\Controllers\Api\OwnerDashboardController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\RentalController;
use App\Http\Controllers\Api\UploadController;
use Illuminate\Support\Facades\Route;

Route::get('/health', fn () => response()->json(['message' => 'LofiSoft API is Healthy']));

// 1. Authentification & Profil
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::middleware('auth:sanctum')->group(function () {
    Route::put('/me', [AuthController::class, 'updateProfile']);
    Route::put('/me/password', [AuthController::class, 'updatePassword']);
    Route::post('/me/identity', [AuthController::class, 'submitIdentity'])->middleware('role:OWNER');
});

// 2. Annonces publiques
Route::get('/announcements', [AnnouncementController::class, 'index']);
Route::get('/announcements/{announcement}', [AnnouncementController::class, 'show'])->name('announcements.show');

// 3. Annonces protégées & Favoris
Route::middleware('auth:sanctum')->group(function () {
    Route::middleware('role:OWNER')->group(function () {
        Route::post('/announcements', [AnnouncementController::class, 'store']);
        Route::put('/announcements/{announcement}', [AnnouncementController::class, 'update']);
        Route::post('/announcements/{announcement}/publish', [AnnouncementController::class, 'publish']);
        Route::post('/announcements/{announcement}/cancel', [AnnouncementController::class, 'cancel']);
        Route::get('/me/announcements', [AnnouncementController::class, 'myAnnouncements']);
    });

    Route::get('/me/favorites', [AnnouncementController::class, 'myFavorites']);
    Route::put('/announcements/{announcement}/favorite', [AnnouncementController::class, 'addFavorite']);
    Route::delete('/announcements/{announcement}/favorite', [AnnouncementController::class, 'removeFavorite']);
    Route::post('/announcements/{announcement}/reports', [AnnouncementController::class, 'report']);
});

// 4. Logements, locations et code logement
Route::get('/housings/lookup', [HousingController::class, 'lookup']);

Route::middleware('auth:sanctum')->group(function () {
    Route::middleware('role:OWNER')->group(function () {
        Route::post('/housings', [HousingController::class, 'store']);
        Route::get('/housings', [HousingController::class, 'index']);
        Route::get('/housings/{housing}', [HousingController::class, 'show']);
        Route::put('/housings/{housing}', [HousingController::class, 'update']);
    });

    Route::post('/rentals/join', [RentalController::class, 'join'])->middleware('role:TENANT');
    Route::get('/me/rental', [RentalController::class, 'currentRental']);
    Route::get('/me/situation', [RentalController::class, 'situation'])->middleware('role:TENANT');
    Route::post('/rentals/{rental}/end', [RentalController::class, 'end']);
});

// 5. Loyers & Paiements (Locataire)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me/rent', [RentalController::class, 'currentRent']);
    Route::get('/me/rent/periods', [RentalController::class, 'rentPeriods']);

    Route::post('/payments', [PaymentController::class, 'store'])->middleware('role:TENANT');
    Route::get('/payments/{payment}', [PaymentController::class, 'show']);
    Route::get('/me/payments', [PaymentController::class, 'myPayments']);
    Route::get('/payments/{payment}/receipt', [PaymentController::class, 'receipt']);
});

Route::post('/payments/webhook', [PaymentController::class, 'webhook']);

// 6. Espace Propriétaire
Route::middleware(['auth:sanctum', 'role:OWNER'])->prefix('owner')->group(function () {
    Route::get('/dashboard', [OwnerDashboardController::class, 'dashboard']);
    Route::get('/tenants', [OwnerDashboardController::class, 'tenants']);
    Route::get('/requests', [OwnerDashboardController::class, 'requests']);
    Route::get('/tenants/{rentalId}', [OwnerDashboardController::class, 'tenantDetails']);
    Route::post('/rentals/{rental}/accept', [OwnerDashboardController::class, 'acceptRental']);
    Route::post('/rentals/{rental}/reject', [OwnerDashboardController::class, 'rejectRental']);
    Route::post('/rentals/{rental}/remind', [OwnerDashboardController::class, 'remind']);
    Route::post('/payments/manual', [OwnerDashboardController::class, 'manualPayment']);
});

// 7. Espace Administration
Route::middleware(['auth:sanctum', 'role:ADMIN'])->prefix('admin')->group(function () {
    Route::get('/identity-requests', [AdminController::class, 'identityRequests']);
    Route::post('/identity-requests/{identityRequest}/approve', [AdminController::class, 'approveIdentity']);
    Route::post('/identity-requests/{identityRequest}/reject', [AdminController::class, 'rejectIdentity']);

    Route::get('/reports', [AdminController::class, 'reports']);
    Route::post('/reports/{report}/resolve', [AdminController::class, 'resolveReport']);
    Route::post('/reports/{report}/dismiss', [AdminController::class, 'dismissReport']);

    Route::get('/users', [AdminController::class, 'users']);
    Route::put('/users/{user}/active', [AdminController::class, 'toggleUserActive']);
});

// 8. Téléversement d'images
Route::middleware('auth:sanctum')->post('/uploads', [UploadController::class, 'store']);
