<?php

namespace App\Models;

use App\Enums\AccommodationType;
use App\Enums\AnnouncementStatus;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Announcement extends Model
{
    use HasUuids;

    protected $fillable = [
        'owner_id',
        'housing_id',
        'title',
        'type',
        'rent',
        'deposit_months',
        'city',
        'district',
        'rooms',
        'description',
        'status',
        'published_at',
    ];

    protected function casts(): array
    {
        return [
            'type' => AccommodationType::class,
            'status' => AnnouncementStatus::class,
            'rent' => 'integer',
            'deposit_months' => 'integer',
            'rooms' => 'integer',
            'published_at' => 'datetime',
        ];
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function housing(): BelongsTo
    {
        return $this->belongsTo(Housing::class);
    }

    public function photos(): HasMany
    {
        return $this->hasMany(AnnouncementPhoto::class)->orderBy('position');
    }

    public function favoritedBy(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'favorites', 'announcement_id', 'user_id');
    }

    public function reports(): HasMany
    {
        return $this->hasMany(Report::class);
    }
}
