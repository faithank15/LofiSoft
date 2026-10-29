<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Tests\TestCase;

class AuthTest extends TestCase
{
    private function payload(array $over = []): array
    {
        return $over + [
            'nom' => 'Agossa',
            'prenoms' => 'Patrick',
            'email' => 'patrick@lofi.bj',
            'telephone' => '0197123456',
            'password' => 'Test1234',
            'role' => 'TENANT',
        ];
    }

    public function test_register_creates_user_and_returns_token(): void
    {
        $this->postJson('/api/auth/register', $this->payload())
            ->assertCreated()
            ->assertJsonStructure(['token', 'user' => ['id', 'nom', 'prenoms', 'email', 'telephone', 'role', 'actif']])
            ->assertJsonPath('user.role', 'TENANT')
            ->assertJsonMissingPath('user.password');

        $this->assertDatabaseHas('users', ['email' => 'patrick@lofi.bj', 'identity_verified' => false]);
    }

    public function test_register_hashes_the_password(): void
    {
        $this->postJson('/api/auth/register', $this->payload());

        $stored = User::where('email', 'patrick@lofi.bj')->value('password');
        $this->assertNotSame('Test1234', $stored);
        $this->assertTrue(password_verify('Test1234', $stored));
    }

    public function test_register_lowercases_the_email(): void
    {
        $this->postJson('/api/auth/register', $this->payload(['email' => 'Patrick@LOFI.bj']))
            ->assertCreated()
            ->assertJsonPath('user.email', 'patrick@lofi.bj');
    }

    public function test_register_can_create_an_owner(): void
    {
        $this->postJson('/api/auth/register', $this->payload(['role' => 'OWNER']))
            ->assertCreated()
            ->assertJsonPath('user.role', 'OWNER');
    }

    public function test_register_refuses_admin_role(): void
    {
        $this->postJson('/api/auth/register', $this->payload(['role' => 'ADMIN']))
            ->assertStatus(422)
            ->assertJsonValidationErrors('role');

        $this->assertDatabaseCount('users', 0);
    }

    public function test_register_ignores_mass_assignment_of_privileged_fields(): void
    {
        $this->postJson('/api/auth/register', $this->payload(['identity_verified' => true, 'actif' => false]))
            ->assertCreated()
            ->assertJsonPath('user.actif', true);

        $this->assertDatabaseHas('users', ['email' => 'patrick@lofi.bj', 'identity_verified' => false]);
    }

    /** @dataProvider invalidRegistrations */
    public function test_register_validation(array $override, string $field): void
    {
        $this->postJson('/api/auth/register', $this->payload($override))
            ->assertStatus(422)
            ->assertJsonValidationErrors($field);
    }

    public static function invalidRegistrations(): array
    {
        return [
            'nom manquant' => [['nom' => ''], 'nom'],
            'prénoms manquants' => [['prenoms' => ''], 'prenoms'],
            'email invalide' => [['email' => 'pas-un-email'], 'email'],
            'téléphone trop court' => [['telephone' => '019712'], 'telephone'],
            'téléphone sans 01' => [['telephone' => '0297123456'], 'telephone'],
            'téléphone avec +229' => [['telephone' => '+22997123456'], 'telephone'],
            'téléphone avec lettres' => [['telephone' => '01971234ab'], 'telephone'],
            'mot de passe court' => [['password' => '1234567'], 'password'],
            'rôle inconnu' => [['role' => 'PIRATE'], 'role'],
            'nom trop long' => [['nom' => str_repeat('a', 101)], 'nom'],
        ];
    }

    public function test_register_rejects_duplicate_email_and_phone(): void
    {
        $this->postJson('/api/auth/register', $this->payload())->assertCreated();

        $this->postJson('/api/auth/register', $this->payload(['telephone' => '0197999999']))
            ->assertStatus(422)->assertJsonValidationErrors('email');

        $this->postJson('/api/auth/register', $this->payload(['email' => 'autre@lofi.bj']))
            ->assertStatus(422)->assertJsonValidationErrors('telephone');
    }

    public function test_register_errors_are_in_french(): void
    {
        $this->postJson('/api/auth/register', [])
            ->assertStatus(422)
            ->assertJsonPath('errors.nom.0', 'Le champ nom est obligatoire.')
            ->assertJsonPath('errors.password.0', 'Le champ mot de passe est obligatoire.');
    }

    public function test_login_success(): void
    {
        $user = $this->user('TENANT', ['email' => 'a@lofi.bj']);

        $this->postJson('/api/auth/login', ['email' => 'a@lofi.bj', 'password' => 'Test1234'])
            ->assertOk()
            ->assertJsonPath('user.id', (string) $user->id)
            ->assertJsonStructure(['token']);
    }

    public function test_login_email_is_case_insensitive(): void
    {
        $this->user('TENANT', ['email' => 'a@lofi.bj']);

        $this->postJson('/api/auth/login', ['email' => 'A@LOFI.BJ', 'password' => 'Test1234'])->assertOk();
    }

    public function test_login_wrong_password_and_unknown_email_give_same_401(): void
    {
        $this->user('TENANT', ['email' => 'a@lofi.bj']);

        $wrong = $this->postJson('/api/auth/login', ['email' => 'a@lofi.bj', 'password' => 'faux']);
        $unknown = $this->postJson('/api/auth/login', ['email' => 'zz@lofi.bj', 'password' => 'Test1234']);

        $wrong->assertStatus(401)->assertJsonPath('message', 'Email ou mot de passe incorrect.');
        $unknown->assertStatus(401);
        $this->assertSame($wrong->json(), $unknown->json());
    }

    public function test_login_refuses_suspended_account(): void
    {
        $this->user('TENANT', ['email' => 'a@lofi.bj', 'actif' => false]);

        $this->postJson('/api/auth/login', ['email' => 'a@lofi.bj', 'password' => 'Test1234'])
            ->assertForbidden()
            ->assertJsonPath('message', 'Ce compte a été suspendu.');
    }

    public function test_login_requires_fields(): void
    {
        $this->postJson('/api/auth/login', [])->assertStatus(422)->assertJsonValidationErrors(['email', 'password']);
    }

    public function test_me_requires_authentication(): void
    {
        $this->getJson('/api/auth/me')->assertUnauthorized()->assertJsonPath('message', 'Authentification requise.');
    }

    public function test_me_returns_current_user_with_real_token(): void
    {
        $token = $this->postJson('/api/auth/register', $this->payload())->json('token');

        $this->withToken($token)->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('user.email', 'patrick@lofi.bj');
    }

    public function test_logout_revokes_the_token(): void
    {
        $token = $this->postJson('/api/auth/register', $this->payload())->json('token');

        $this->withToken($token)->postJson('/api/auth/logout')->assertNoContent();
        $this->assertDatabaseCount('personal_access_tokens', 0);

        $this->app['auth']->forgetGuards();
        $this->withToken($token)->getJson('/api/auth/me')->assertUnauthorized();
    }

    public function test_suspended_user_with_existing_token_is_locked_out(): void
    {
        $token = $this->postJson('/api/auth/register', $this->payload())->json('token');
        User::where('email', 'patrick@lofi.bj')->update(['actif' => false]);

        $this->app['auth']->forgetGuards();
        $this->withToken($token)->getJson('/api/auth/me')->assertUnauthorized()->assertJsonPath('message', 'Ce compte a été suspendu.');
    }

    public function test_forgot_password_never_reveals_whether_email_exists(): void
    {
        $this->user('TENANT', ['email' => 'a@lofi.bj']);

        $known = $this->postJson('/api/auth/forgot-password', ['email' => 'a@lofi.bj']);
        $unknown = $this->postJson('/api/auth/forgot-password', ['email' => 'zz@lofi.bj']);

        $known->assertOk();
        $this->assertSame($known->json(), $unknown->json());
        $this->postJson('/api/auth/forgot-password', ['email' => 'nope'])->assertStatus(422);
    }
}
