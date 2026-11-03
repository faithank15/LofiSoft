<?php

namespace App\Models;

use App\Enums\UserRole;
use App\Notifications\ResetPasswordNotification;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasUuids, Notifiable;

    protected $fillable = [
        'nom',
        'prenoms',
        'email',
        'telephone',
        'password',
        'role',
        'actif',
        'identity_verified',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'role' => UserRole::class,
            'actif' => 'boolean',
            'identity_verified' => 'boolean',
            'password' => 'hashed',
        ];
    }

    public function housings(): HasMany
    {
        return $this->hasMany(Housing::class, 'owner_id');
    }

    public function announcements(): HasMany
    {
        return $this->hasMany(Announcement::class, 'owner_id');
    }

    public function rentals(): HasMany
    {
        return $this->hasMany(Rental::class, 'tenant_id');
    }

    public function activeRental(): HasOne
    {
        return $this->hasOne(Rental::class, 'tenant_id')->where('status', 'ACTIVE');
    }

    public function favorites(): BelongsToMany
    {
        return $this->belongsToMany(Announcement::class, 'favorites', 'user_id', 'announcement_id');
    }

    public function identityRequests(): HasMany
    {
        return $this->hasMany(IdentityRequest::class, 'owner_id');
    }

    /**
     * Envoi du lien de réinitialisation du mot de passe.
     *
     * On remplace la notification par défaut de Laravel (anglaise) par la
     * nôtre, qui renvoie vers la page web de réinitialisation.
     */
    public function sendPasswordResetNotification($token): void
    {
        $this->notify(new ResetPasswordNotification($token));
    }
}
