<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use App\Notifications\ResetPasswordNotification;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
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

    public function test_register_requires_at_least_a_name(): void
    {
        $this->postJson('/api/auth/register', $this->payload(['nom' => '', 'prenoms' => '']))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['nom', 'prenoms']);
    }

    public function test_register_tolerates_one_missing_name_by_copying_the_other(): void
    {
        $this->postJson('/api/auth/register', $this->payload(['nom' => '', 'prenoms' => 'Patrick']))
            ->assertCreated()
            ->assertJsonPath('user.nom', 'Patrick')
            ->assertJsonPath('user.prenoms', 'Patrick');
    }

    public function test_register_splits_a_full_name_sent_alone(): void
    {
        $payload = $this->payload();
        unset($payload['nom'], $payload['prenoms']);

        $this->postJson('/api/auth/register', $payload + ['fullName' => 'Jean Pierre Agossa'])
            ->assertCreated()
            ->assertJsonPath('user.prenoms', 'Jean Pierre')
            ->assertJsonPath('user.nom', 'Agossa');
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
            ->assertJsonPath('errors.nom.0', 'Le nom de famille est obligatoire.')
            ->assertJsonPath('errors.password.0', 'Le mot de passe est obligatoire.');
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

    public function test_forgot_password_sends_a_real_email_with_a_working_link(): void
    {
        Notification::fake();

        $this->user('TENANT', ['email' => 'a@lofi.bj']);

        $this->postJson('/api/auth/forgot-password', ['email' => 'a@lofi.bj'])->assertOk();

        Notification::assertSentTo(
            User::where('email', 'a@lofi.bj')->first(),
            ResetPasswordNotification::class,
            function (ResetPasswordNotification $notification, array $channels, object $notifiable): bool {
                $mail = $notification->toMail($notifiable);

                // Le lien doit viser la page web de réinitialisation.
                $this->assertStringContainsString('/reset-password?token=', $mail->actionUrl);
                $this->assertStringContainsString('email=a%40lofi.bj', $mail->actionUrl);
                $this->assertStringContainsString('Réinitialisez votre mot de passe', $mail->subject);
                $this->assertSame('Choisir un nouveau mot de passe', $mail->actionText);

                return true;
            }
        );
    }

    public function test_forgot_password_stores_a_token_that_can_reset_the_password(): void
    {
        $user = $this->user('TENANT', ['email' => 'a@lofi.bj']);

        $this->postJson('/api/auth/forgot-password', ['email' => 'a@lofi.bj'])->assertOk();

        // Un jeton doit exister en base, et la page web doit réinitialiser le mot de passe.
        $this->assertDatabaseHas('password_reset_tokens', ['email' => 'a@lofi.bj']);

        $token = Password::broker()->createToken($user);

        $this->post('/reset-password', [
            'token' => $token,
            'email' => 'a@lofi.bj',
            'password' => 'Nouveau1234',
            'password_confirmation' => 'Nouveau1234',
        ])->assertOk()->assertSee('Mot de passe modifié', false);

        $this->assertTrue(Hash::check('Nouveau1234', $user->fresh()->password));
    }

    public function test_reset_password_rejects_an_invalid_token(): void
    {
        $user = $this->user('TENANT', ['email' => 'a@lofi.bj']);

        $this->post('/reset-password', [
            'token' => 'jeton-bidon',
            'email' => 'a@lofi.bj',
            'password' => 'Nouveau1234',
            'password_confirmation' => 'Nouveau1234',
        ])->assertOk()->assertSee('invalide ou a expiré', false);

        // Le mot de passe n'a pas bougé.
        $this->assertTrue(Hash::check('Test1234', $user->fresh()->password));
    }

    public function test_reset_password_page_is_reachable_and_renders_the_form(): void
    {
        $this->get('/reset-password?token=abc&email=a%40lofi.bj')
            ->assertOk()
            ->assertSee('Choisir un nouveau mot de passe')
            ->assertSee('name="token"', false)
            ->assertSee('value="abc"', false);
    }

    public function test_reset_password_requires_a_matching_confirmation(): void
    {
        $user = $this->user('TENANT', ['email' => 'a@lofi.bj']);

        // Un navigateur, pas un client JSON : la page doit se réafficher avec l'erreur.
        $this->withHeader('Accept', 'text/html')->post('/reset-password', [
            'token' => 'jeton-bidon',
            'email' => 'a@lofi.bj',
            'password' => 'Nouveau1234',
            'password_confirmation' => 'Autre1234',
        ])->assertSessionHasErrors('password');

        $this->assertTrue(Hash::check('Test1234', $user->fresh()->password));
    }

    public function test_the_reset_email_renders_as_html_with_its_link(): void
    {
        $user = $this->user('TENANT', ['email' => 'a@lofi.bj']);

        $mail = (new ResetPasswordNotification('jeton-de-test'))->toMail($user);
        $rendered = $mail->render();

        // Le mail doit être affichable : lien cliquable et texte en français.
        $this->assertStringContainsString('/reset-password?token=jeton-de-test', $rendered);
        $this->assertStringContainsString('Choisir un nouveau mot de passe', $rendered);
        $this->assertStringContainsString('ignorez simplement ce message', $rendered);
    }

    public function test_resetting_the_password_revokes_the_open_sessions(): void
    {
        $user = $this->user('TENANT', ['email' => 'a@lofi.bj']);
        $user->createToken('auth_token');
        $this->assertSame(1, $user->tokens()->count());

        $token = Password::broker()->createToken($user);

        $this->post('/reset-password', [
            'token' => $token,
            'email' => 'a@lofi.bj',
            'password' => 'Nouveau1234',
            'password_confirmation' => 'Nouveau1234',
        ])->assertOk();

        // Un mot de passe réinitialisé doit fermer les sessions ouvertes.
        $this->assertSame(0, $user->fresh()->tokens()->count());
    }
}
