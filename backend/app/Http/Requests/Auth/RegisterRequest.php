<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Normalise la requête avant validation pour tolérer les saisies combinées
     * ou les clients qui transmettent un champ unique.
     */
    protected function prepareForValidation(): void
    {
        $fullName = $this->input('fullName') ?? $this->input('name') ?? $this->input('nom_complet');

        if ($fullName && (! $this->filled('nom') || ! $this->filled('prenoms'))) {
            $parts = preg_split('/\s+/', trim((string) $fullName));
            $nom = count($parts) > 1 ? array_pop($parts) : ($parts[0] ?? '');
            $prenoms = ! empty($parts) ? implode(' ', $parts) : $nom;

            $this->merge([
                'nom' => $this->input('nom', $nom),
                'prenoms' => $this->input('prenoms', $prenoms),
            ]);
        }

        // Si seul le nom est renseigné, on extrait ou on réplique pour éviter le rejet 422
        if ($this->filled('nom') && ! $this->filled('prenoms')) {
            $parts = preg_split('/\s+/', trim((string) $this->input('nom')));
            if (count($parts) > 1) {
                $nom = array_pop($parts);
                $prenoms = implode(' ', $parts);
                $this->merge([
                    'nom' => $nom,
                    'prenoms' => $prenoms,
                ]);
            } else {
                $this->merge([
                    'prenoms' => $this->input('nom'),
                ]);
            }
        } elseif ($this->filled('prenoms') && ! $this->filled('nom')) {
            $this->merge([
                'nom' => $this->input('prenoms'),
            ]);
        }
    }

    public function rules(): array
    {
        return [
            'nom' => ['required', 'string', 'max:100'],
            'prenoms' => ['required', 'string', 'max:100'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'telephone' => ['required', 'string', 'regex:/^01[0-9]{8}$/', 'unique:users,telephone'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['required', 'string', 'in:TENANT,OWNER'],
        ];
    }

    public function messages(): array
    {
        return [
            'nom.required' => 'Le nom de famille est obligatoire.',
            'prenoms.required' => 'Le ou les prénoms sont obligatoires.',
            'email.required' => 'L\'adresse e-mail est obligatoire.',
            'email.email' => 'L\'adresse e-mail n\'est pas valide.',
            'email.unique' => 'Cette adresse e-mail est déjà prise.',
            'telephone.required' => 'Le numéro de téléphone est obligatoire.',
            'telephone.unique' => 'Ce numéro de téléphone est déjà utilisé.',
            'telephone.regex' => 'Le téléphone doit comporter 10 chiffres commençant par 01.',
            'password.required' => 'Le mot de passe est obligatoire.',
            'password.min' => 'Le mot de passe doit comporter au moins 8 caractères.',
            'role.in' => 'Le rôle doit être TENANT ou OWNER.',
        ];
    }
}
