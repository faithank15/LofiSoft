# Reconstruire le backend, étape par étape

Même principe que pour le mobile : de l'intérieur vers l'extérieur. Base de données d'abord, puis modèles, puis routes et contrôleurs, puis règles métier. À chaque palier, un test.

---

## Étape 1 — Le projet et la base

```
composer create-project laravel/laravel backend
cd backend
php artisan install:api          # installe Sanctum, crée routes/api.php et la table des jetons
```

`.env` : `DB_CONNECTION=mysql`, `DB_DATABASE=lofisoft`, utilisateur et mot de passe de XAMPP. Créer la base `lofisoft` (phpMyAdmin ou `mysql -uroot -e "create database lofisoft"`).

Les tests, eux, n'utilisent pas MySQL : `phpunit.xml` les met sur SQLite en mémoire, ce qui les rend rapides et sans effet de bord.

Vérifier : `php artisan serve` puis `curl http://127.0.0.1:8000/api/health` (route ajoutée dans `routes/api.php`).

---

## Étape 2 — Le schéma : migrations, énumérations, modèles

Ordre des migrations (les clés étrangères imposent l'ordre : on crée d'abord la table référencée) :

1. `users` (modifiée : `nom`, `prenoms`, `telephone` unique, `role`, `actif`, `identity_verified`)
2. `personal_access_tokens` (Sanctum, jetons liés à un `uuidMorphs`)
3. `housings` : `owner_id`, `title`, `type`, `rent`, `due_day`, `city`, `district`, `code` **unique**
4. `rentals` : `housing_id`, `tenant_id`, `status`, `started_at`, `ended_at`
5. `rent_periods` : `rental_id`, `period` (`AAAA-MM`), `total`, `carried_over`, `due_date`, **unique** `(rental_id, period)`
6. `payments` : `rental_id`, `period`, `amount`, `operator`, `phone`, `status`, `reference` unique, `provider_ref`, `paid_at`
7. `announcements`, `announcement_photos`, `favorites` (clé primaire composée `user_id` + `announcement_id`), `identity_requests`, `reports`

Choix à comprendre :

- `foreignUuid(...)->constrained(...)->cascadeOnDelete()` : supprimer un utilisateur supprime ses logements, etc. `nullOnDelete()` pour `announcements.housing_id` : supprimer un logement garde l'annonce.
- Les **statuts sont des chaînes** (`PENDING`, `ACTIVE`...), lues par une énumération PHP dans le modèle. La base reste simple, le code garde le contrôle des valeurs.
- Les contraintes d'unicité (`code`, `telephone`, `(rental_id, period)`) sont la **dernière ligne de défense** contre les doublons, même si la validation les attrape avant.

Chaque modèle déclare :

```php
class Housing extends Model {
    use HasUuids;                                   // id = UUID généré automatiquement
    protected $fillable = [...];                    // champs autorisés en écriture de masse
    protected function casts(): array {             // conversions automatiques
        return ['type' => AccommodationType::class, 'rent' => 'integer', 'photos' => 'array'];
    }
    protected static function booted(): void {      // à la création, génère le code s'il est vide
        static::creating(function (Housing $housing) {
            if (empty($housing->code)) { $housing->code = self::generateUniqueCode(); }
        });
    }
    public function owner(): BelongsTo { ... }      // relations
    public function activeRental(): HasOne { return $this->hasOne(Rental::class)->where('status', 'ACTIVE'); }
}
```

Le `User` cache `password` et `remember_token` (`$hidden`) : ils ne sortent jamais en JSON.

Pour le jeu de données : `database/seeders/DatabaseSeeder.php` crée les comptes de démonstration (`locataire@lofi.bj`, `proprio@lofi.bj`, `admin@lofi.bj`, mot de passe `Test1234`), des logements, des annonces, une location active.

Vérifier : `php artisan migrate:fresh --seed` sans erreur, puis `php artisan test tests/Feature/SeederIntegrityTest.php`.

---

## Étape 3 — L'authentification

Fichiers : `routes/api.php`, `app/Http/Controllers/Api/AuthController.php`, `app/Http/Requests/Auth/RegisterRequest.php`, `app/Http/Resources/UserResource.php`, `bootstrap/app.php`.

`register` : valide (`RegisterRequest`), crée l'utilisateur (`Hash::make`), `createToken('auth_token')->plainTextToken`, répond **201** avec `{ token, user }`.

`login` : cherche par e-mail (en minuscules), `Hash::check`. Mauvais identifiants → **401** `Email ou mot de passe incorrect.` (volontairement le même message pour un e-mail inconnu et un mauvais mot de passe : on ne révèle pas quels comptes existent). Compte suspendu → **403**.

`me`, `logout` (supprime **ce** jeton), `updateProfile`, `updatePassword`, `forgotPassword` (répond toujours pareil), `submitIdentity`.

`UserResource` : la **forme unique** d'un utilisateur dans toutes les réponses (`id`, `nom`, `prenoms`, `email`, `telephone`, `role`, `actif`, `identity_verified`, `created_at`). Utilisée par register, login, me, update profil et la liste admin. Avant, quatre blocs identiques étaient recopiés : on en avait oublié un champ, d'où le bug « `identity_verified` absent ».

`bootstrap/app.php` fixe le **contrat d'erreurs** (404, 403, 401 en `{ message }` français pour les routes `/api/*`).

À comprendre : `RegisterRequest::prepareForValidation` est **tolérant** (si `prenoms` seul est envoyé, il est recopié dans `nom`). C'est volontaire, pour accepter des clients qui envoient un champ unique, mais c'est une règle de plus à connaître.

**Vérifier** : `php artisan test tests/Feature/Auth`.

---

## Étape 4 — Rôles et comptes actifs

Fichiers : `app/Http/Middleware/EnsureRole.php`, `EnsureActiveAccount.php`, enregistrés dans `bootstrap/app.php`.

```php
$middleware->alias(['role' => EnsureRole::class]);        // utilisable : ->middleware('role:OWNER')
$middleware->api(append: [EnsureActiveAccount::class]);   // exécuté sur TOUTES les routes /api
$middleware->appendToPriorityList(after: AuthenticatesRequests::class, append: EnsureRole::class);
```

La dernière ligne règle l'**ordre** : le rôle est vérifié avant que Laravel ne retrouve le modèle de l'URL. Sans elle, un locataire qui tape l'id d'une ressource admin verrait 404 si elle n'existe pas et 403 si elle existe : il apprendrait quels ids existent.

`EnsureRole::handle($request, $next, string ...$roles)` : compare `$request->user()->role->value` à la liste, sinon **403** avec un message propre au rôle attendu.

`EnsureActiveAccount` : utilisateur de sanctum avec `actif = false` → **401**. Un compte suspendu perd donc l'accès **immédiatement**, même avec un jeton encore valide ; le mobile, lui, efface sa session sur ce 401.

**Exercice** : `backend-roles`. Test : `RoleMiddlewareTest` (`test_role_matrix` essaie chaque route protégée avec chaque rôle).

---

## Étape 5 — Logements, annonces, images

`HousingController` (propriétaire seulement, sauf `lookup`) :

- `store` : valide (`rent >= 1000`, `due_day` entre 1 et 28, `type` dans `HOUSE,ROOM,OTHER`), crée via `$request->user()->housings()->create(...)` : le `owner_id` est posé **par le serveur**, jamais lu dans la requête.
- `show`, `update` : « ce logement est-il à moi ? » (`$housing->owner_id !== $request->user()->id` → 403). Cette vérification de **propriété** est répétée dans chaque méthode : c'est ce qui empêche un propriétaire de modifier le logement d'un autre.
- `lookup?code=ABC-DEF` : **public** (sans jeton). Met le code en majuscules, trouve le logement, renvoie `{ housing: {... owner_name, owner_verified } }` ou 404 : le locataire voit ce qu'il va rejoindre avant de confirmer.

`AnnouncementController` :

- `index` (**public**) : filtres `city`, `type`, `min_price`, `max_price`, `q`, pagination `per_page` plafonnée à 50, réponse `{ data: [...], meta: { current_page, last_page, total } }`. Seules les annonces `PUBLISHED` y figurent.
- `show` : une annonce non publiée n'est visible que par son propriétaire (`abort(404)` pour les autres, pour ne pas révéler son existence).
- `store` : crée en `DRAFT`. `housing_id` est validé par `Rule::exists('housings', 'id')->where('owner_id', ...)` : on ne peut lier **que son propre** logement. Remarque : côté API, `housing_id` est facultatif ; c'est l'application mobile qui l'impose (« une annonce se base sur un logement existant »).
- `publish` (`DRAFT` → `PUBLISHED`, 409 si annulée), `cancel`, `update`, `myAnnouncements`.
- Favoris : `syncWithoutDetaching` (ajouter deux fois ne crée pas de doublon).
- `report` : un signalement avec motif obligatoire.

`UploadController` + `ImageStorage` : voir [03](03-architecture-backend.md). Le mobile envoie les photos **avant** de créer l'annonce, puis passe leurs URL dans `photos`.

---

## Étape 6 — La location

`RentalController` et `OwnerDashboardController`. Le cycle de vie :

```
locataire : POST /rentals/join {code}      → Rental PENDING   (409 si déjà une location ACTIVE/PENDING,
                                                               404 si code inconnu, 409 si logement occupé)
propriétaire : GET /owner/requests          → les demandes PENDING de SES logements
propriétaire : POST /owner/rentals/{id}/accept → ACTIVE         (409 si pas PENDING, ou logement déjà occupé)
propriétaire : POST /owner/rentals/{id}/reject → la ligne est SUPPRIMÉE
propriétaire : POST /rentals/{id}/end       → FINISHED + ended_at
locataire : GET /me/situation               → { status: NONE|PENDING|ACTIVE, rental_id, housing, owner }
```

Points à comprendre :

- `situation` répond **toujours 200**, même sans location (`status: NONE`) : l'app choisit son écran sans traiter une erreur comme un cas normal. Les endpoints plus anciens (`/me/rental`, `/me/rent`) répondent 404 sans location.
- Les vérifications de propriété passent par le logement (`$rental->housing->owner_id`), pas par la location.
- Les **409** sont des conflits métier (l'état actuel ne permet pas l'action), distincts des **422** (données invalides) et **403** (pas le droit).

**Exercice** : `backend-location`. Test : `RentalTest`.

---

## Étape 7 — Loyers et paiements

`app/Services/RentBalance.php` : trois méthodes qui forment le cœur de l'argent.

```php
due($rental, $period)       // total + report de la période, sinon le loyer du logement
paid($rental, $period)      // somme des paiements SUCCESS de la période
remaining($rental, $period) // max(0, due - paid)
```

`PaymentController::store` : contrôle que la location est bien au locataire (403) et `ACTIVE` (409), que `amount <= remaining` (422, « Le montant dépasse le solde restant à payer »), crée un paiement **PENDING** et répond 201 `{ payment: {...} }`.

`show` règle le paiement en mode simulé (`settleSimulated`) : après `fake_delay` secondes, `SUCCESS` (sauf numéro finissant par `00` : `FAILED`). `receipt` : 400 tant que le paiement n'a pas abouti.

`OwnerDashboardController::manualPayment` : le propriétaire enregistre un paiement en espèces (montant ≥ 1, période `AAAA-MM`, note facultative).

`RolloverRentPeriods` (`php artisan rent:rollover`, planifiée le 1er du mois à 00:05) : pour chaque location `ACTIVE`, crée la période du mois (`total` = loyer, `due_date` = jour d'échéance borné au nombre de jours du mois) et y reporte l'impayé du mois précédent (`carried_over`).

**Exercice** : `backend-solde`. Test : `PaymentTest`.

Piège rencontré : en mode simulé, un paiement reste `PENDING` tant que personne ne le **relit** après le délai. Un test qui attend le loyer mis à jour sans relire le paiement échoue.

---

## Étape 8 — Administration

`AdminController` (route `role:ADMIN` en bloc) :

- `reports?status=PENDING` : renvoie un **tableau direct** (pas `{ data }`) ; le mobile l'enveloppe lui-même (`ApiClient` transforme une liste JSON en `{'data': liste}`). Chaque ligne contient l'annonce, la ville, le propriétaire et `reports_count`.
- `resolveReport` (`REMOVE_ANNOUNCEMENT` → l'annonce passe `CANCELED` ; `WARN_OWNER`) et `dismissReport`.
- `identityRequests`, `approveIdentity` (met `users.identity_verified = true`), `rejectIdentity` (motif obligatoire).
- `users` : filtres `role` et `q`, pagination `per_page`, réponse `{ data: [UserResource...], meta }`.
- `toggleUserActive` : `{ actif: bool }` ; 422 si l'administrateur vise son propre compte.

**Exercice** : `backend-admin`. Test : `AdminTest`.

---

## Étape 9 — Les tests

```php
class AdminTest extends TestCase {          // TestCase (tests/TestCase.php) fournit déjà RefreshDatabase et BuildsData

    public function test_me_exposes_identity_verified_for_owner_badge(): void {
        $owner = $this->actingAsRole('OWNER', ['identity_verified' => false]);
        $this->getJson('/api/auth/me')->assertOk()->assertJsonPath('user.identity_verified', false);
        $owner->update(['identity_verified' => true]);
        $this->getJson('/api/auth/me')->assertOk()->assertJsonPath('user.identity_verified', true);
    }
}
```

- `RefreshDatabase` (déjà inclus par `tests/TestCase.php`) : base SQLite en mémoire, refaite à chaque test. Le même fichier envoie `Accept: application/json` pour que les erreurs reviennent en JSON.
- `actingAsRole('OWNER')` : crée un utilisateur et le connecte (Sanctum) sans passer par le login.
- `getJson`, `postJson`, `putJson` envoient du JSON avec `Accept: application/json` ; `assertOk`, `assertForbidden`, `assertJsonCount`, `assertJsonStructure`, `assertJsonPath` vérifient la réponse.
- Une bonne habitude du projet : tester **le refus** autant que le succès (mauvais rôle, ressource d'autrui, données invalides).

Lancer : `php artisan test` (250 tests). Un fichier : `php artisan test tests/Feature/AdminTest.php`.

**Exercice final** : ajoutez un endpoint de votre choix (par exemple `GET /me/stats`), écrivez son test **avant**, regardez-le échouer, puis implémentez.

---

## Incohérences connues à garder en tête

| Sujet | Détail |
|---|---|
| Listes sans enveloppe | `GET /admin/reports` et `GET /admin/identity-requests` renvoient un tableau nu ; les autres listes renvoient `{ data, meta }`. Le mobile compense. |
| `housing_id` d'annonce | facultatif côté API, obligatoire côté application mobile. |
| Inscription tolérante | un seul champ parmi `nom` et `prenoms` suffit. |
| Fin de location | `POST /rentals/{id}/end` ne vérifie pas que la location est `ACTIVE` avant de la passer en `FINISHED`. |
