<?php

namespace Tests\Feature;

use Tests\TestCase;

/** Matrice routes × rôles : chaque route protégée refuse les rôles non prévus. */
class RoleMiddlewareTest extends TestCase
{
    /** @dataProvider matrix */
    public function test_role_matrix(string $method, string $uri, string $allowedRole): void
    {
        $uri = str_replace('{id}', fake()->uuid(), $uri);

        foreach (['TENANT', 'OWNER', 'ADMIN'] as $role) {
            $this->actingAsRole($role);
            $status = $this->json($method, $uri)->status();

            $role === $allowedRole
                ? $this->assertNotSame(403, $status, "$role devrait passer sur $method $uri")
                : $this->assertSame(403, $status, "$role devrait être refusé sur $method $uri (reçu $status)");
        }
    }

    public static function matrix(): array
    {
        return [
            ['POST', '/api/announcements', 'OWNER'],
            ['PUT', '/api/announcements/{id}', 'OWNER'],
            ['POST', '/api/announcements/{id}/publish', 'OWNER'],
            ['POST', '/api/announcements/{id}/cancel', 'OWNER'],
            ['GET', '/api/me/announcements', 'OWNER'],
            ['POST', '/api/housings', 'OWNER'],
            ['GET', '/api/housings', 'OWNER'],
            ['GET', '/api/housings/{id}', 'OWNER'],
            ['PUT', '/api/housings/{id}', 'OWNER'],
            ['POST', '/api/me/identity', 'OWNER'],
            ['GET', '/api/owner/dashboard', 'OWNER'],
            ['GET', '/api/owner/tenants', 'OWNER'],
            ['GET', '/api/owner/tenants/{id}', 'OWNER'],
            ['POST', '/api/owner/rentals/{id}/accept', 'OWNER'],
            ['POST', '/api/owner/rentals/{id}/reject', 'OWNER'],
            ['POST', '/api/owner/rentals/{id}/remind', 'OWNER'],
            ['POST', '/api/owner/payments/manual', 'OWNER'],
            ['POST', '/api/rentals/join', 'TENANT'],
            ['POST', '/api/payments', 'TENANT'],
            ['GET', '/api/admin/users', 'ADMIN'],
            ['GET', '/api/admin/reports', 'ADMIN'],
            ['GET', '/api/admin/identity-requests', 'ADMIN'],
            ['PUT', '/api/admin/users/{id}/active', 'ADMIN'],
        ];
    }

    public function test_all_protected_routes_reject_anonymous(): void
    {
        $public = ['api/health', 'api/auth/register', 'api/auth/login', 'api/auth/forgot-password', 'api/announcements',
            'api/announcements/{announcement}', 'api/housings/lookup', 'api/payments/webhook'];

        foreach (app('router')->getRoutes() as $route) {
            if (! str_starts_with($route->uri(), 'api/') || in_array($route->uri(), $public, true)) {
                continue;
            }
            $uri = '/'.preg_replace('/\{[^}]+\}/', fake()->uuid(), $route->uri());
            $method = collect($route->methods())->first(fn ($m) => ! in_array($m, ['HEAD']));

            $this->json($method, $uri)->assertUnauthorized();
        }
    }
}
