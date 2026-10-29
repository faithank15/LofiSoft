<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'nom' => fake()->lastName(),
            'prenoms' => fake()->firstName(),
            'email' => fake()->unique()->safeEmail(),
            'telephone' => '01'.fake()->unique()->numerify('########'),
            'password' => static::$password ??= Hash::make('Test1234'),
            'role' => 'TENANT',
            'actif' => true,
            'identity_verified' => false,
            'remember_token' => Str::random(10),
        ];
    }
}
