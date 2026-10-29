<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AnnouncementResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user = $request->user('sanctum');
        $isFavorite = false;

        if ($user && $user->role->value === 'TENANT') {
            $isFavorite = $this->favoritedBy()->where('users.id', $user->id)->exists();
        }

        $data = [
            'id' => (string) $this->id,
            'title' => $this->title,
            'type' => $this->type->value ?? (string) $this->type,
            'rent' => (int) $this->rent,
            'deposit_months' => (int) $this->deposit_months,
            'city' => $this->city,
            'district' => $this->district,
            'rooms' => (int) $this->rooms,
            'photos' => $this->photos->pluck('url')->toArray(),
            'verified' => (bool) ($this->owner?->identity_verified ?? false),
            'is_favorite' => $isFavorite,
            'status' => $this->status->value ?? (string) $this->status,
            'published_at' => $this->published_at?->toISOString(),
        ];

        if ($request->routeIs('announcements.show')) {
            $data['description'] = $this->description;
            $data['owner'] = [
                'id' => (string) $this->owner_id,
                'name' => trim(($this->owner?->prenoms ?? '') . ' ' . ($this->owner?->nom ?? '')),
            ];
        }

        return $data;
    }
}
