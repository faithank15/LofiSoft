<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'nom' => $this->nom,
            'prenoms' => $this->prenoms,
            'email' => $this->email,
            'telephone' => $this->telephone,
            'role' => $this->role instanceof \BackedEnum ? $this->role->value : (string) $this->role,
            'actif' => (bool) $this->actif,
            'identity_verified' => (bool) $this->identity_verified,
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
