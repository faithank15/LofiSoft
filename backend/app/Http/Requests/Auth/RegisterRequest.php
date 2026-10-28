<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
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
            'email.unique' => 'Cette adresse e-mail est déjà prise.',
            'telephone.unique' => 'Ce numéro de téléphone est déjà utilisé.',
            'telephone.regex' => 'Le téléphone doit comporter 10 chiffres commençant par 01.',
            'role.in' => 'Le rôle doit être TENANT ou OWNER.',
        ];
    }
}
