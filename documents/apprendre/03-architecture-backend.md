# Architecture du backend (Laravel 12)

## Le trajet d'une requête

```
Mobile : POST http://.../api/auth/login
   │
public/index.php            point d'entrée unique
bootstrap/app.php           configure routage, middlewares, format des erreurs
routes/api.php              associe URL + verbe à un contrôleur (préfixe /api automatique)
   │   middlewares, dans l'ordre :
   │     auth:sanctum        lit le jeton « Authorization: Bearer », retrouve l'utilisateur, sinon 401
   │     EnsureActiveAccount compte suspendu : 401
   │     role:OWNER          mauvais rôle : 403
app/Http/Controllers/Api/   valide la requête, applique les règles, répond en JSON
app/Models/ (Eloquent)      lit et écrit la base MySQL
```

Le contrôleur est mince : il valide, vérifie qui a le droit, appelle les modèles ou un service, renvoie du JSON. La logique réutilisable (calcul du solde, envoi d'images) vit dans `app/Services/`.

## Les briques et leur rôle

| Brique | Dossier | Rôle |
|---|---|---|
| Migration | `database/migrations` | Décrit une table. L'historique des migrations **est** le schéma. |
| Modèle | `app/Models` | Une classe par table : champs autorisés (`$fillable`), conversions (`casts`), relations. |
| Énumération | `app/Enums` | Valeurs fermées (`UserRole`, `RentalStatus`...). Un modèle les lit via `casts`. |
| Contrôleur | `app/Http/Controllers/Api` | Un endpoint = une méthode. |
| Resource | `app/Http/Resources` | Forme exacte du JSON d'un modèle (`UserResource`, `AnnouncementResource`). |
| Middleware | `app/Http/Middleware` | Code qui s'exécute avant le contrôleur (`EnsureRole`, `EnsureActiveAccount`). |
| Service | `app/Services` | Logique partagée (`RentBalance`, `ImageStorage`, `CloudinaryService`). |
| Commande | `app/Console/Commands` | Tâche en ligne de commande (`rent:rollover`), planifiée dans `routes/console.php`. |
| Seeder | `database/seeders` | Données de démonstration (comptes `@lofi.bj`, mot de passe `Test1234`). |

## Authentification : Sanctum

1. `POST /auth/register` ou `/auth/login` : le serveur vérifie, puis `createToken(...)` fabrique un **jeton** et le renvoie avec l'utilisateur.
2. Le mobile le garde (`AuthStorage`) et l'envoie à chaque appel : `Authorization: Bearer <jeton>`.
3. `auth:sanctum` retrouve l'utilisateur à partir du jeton. `POST /auth/logout` supprime ce jeton : il ne marche plus (testé).

Un mot de passe n'est jamais stocké en clair : `Hash::make` à l'inscription, `Hash::check` à la connexion. Le champ `password` n'apparaît dans aucune réponse (vérifié par les tests).

## Rôles et comptes

- Trois rôles : `TENANT`, `OWNER`, `ADMIN`. À l'inscription, seuls `TENANT` et `OWNER` sont acceptés (`in:TENANT,OWNER`) : on ne devient pas administrateur en le demandant.
- `->middleware('role:OWNER')` protège une route. `EnsureRole` compare le rôle de l'utilisateur à la liste et répond **403** avec un message en français.
- `EnsureActiveAccount` est ajouté à tout le groupe `api` : un compte suspendu (`actif = false`) reçoit **401**, y compris avec un jeton valide. Le mobile efface alors sa session.
- Ordre voulu (`bootstrap/app.php`) : le rôle est vérifié **avant** la résolution des modèles de la route. Sinon un locataire qui tape `/admin/users/<id>` recevrait 404 ou 403 selon que l'id existe, ce qui révèle l'existence d'un identifiant.

## Le contrat d'erreurs

Toute erreur de l'API a la forme `{ "message": "..." }` en français, et les erreurs de validation ajoutent `errors` :

```json
{ "message": "Ce numéro de téléphone est déjà utilisé.",
  "errors": { "telephone": ["Ce numéro de téléphone est déjà utilisé."] } }
```

| Code | Quand |
|---|---|
| 401 | jeton absent, invalide, ou compte suspendu |
| 403 | mauvais rôle, ou ressource d'un autre utilisateur |
| 404 | ressource introuvable (rendu en JSON pour `/api/*` dans `bootstrap/app.php`) |
| 409 | conflit métier : déjà une location, logement déjà occupé, demande déjà traitée |
| 422 | données invalides |

Le mobile (`ApiClient._handle`) lit exactement ce format : 401 → `UnauthorizedException`, 400 et 422 → `ValidationException` (premier message de `errors`), 5xx → `ServerException`. **Si vous changez la forme d'une erreur côté Laravel, vous cassez l'affichage côté mobile.**

## Le modèle de données

```
users ──< housings ──< rentals >── users (le locataire)
              │            │
              │            ├──< rent_periods   (une ligne par mois : total + report)
              │            └──< payments       (un paiement = un essai, PENDING puis SUCCESS/FAILED)
              └──< announcements ──< announcement_photos
                        ├── favorites (users × annonces)
                        └──< reports (signalements)
users ──< identity_requests (demande de badge « Vérifié »)
```

Points à comprendre :

- **Identifiants UUID** partout (`HasUuids`), pas d'entiers : on ne devine pas l'id suivant.
- **Un logement a un `code`** de la forme `ABC-DEF`, généré à la création (`Housing::generateUniqueCode`, en boucle jusqu'à un code libre). Le locataire le saisit pour demander à rejoindre.
- **Annonce ≠ logement.** Le logement est le bien (loyer, jour d'échéance, code) ; l'annonce est sa publicité (titre, photos, statut `DRAFT` → `PUBLISHED`). Une annonce se crée **à partir** d'un logement du propriétaire (`housing_id`, vérifié par `Rule::exists(...)->where('owner_id', ...)`).
- **Location (`rentals`)** : `PENDING` (le locataire a saisi le code) → `ACTIVE` (le propriétaire accepte) → `FINISHED` (le propriétaire met fin). Un refus **supprime** la ligne. Règles : un locataire n'a qu'une location `ACTIVE` ou `PENDING` à la fois (409) ; un logement n'a qu'une location `ACTIVE` (409).
- **Période de loyer (`rent_periods`)** : une ligne par location et par mois (`AAAA-MM`) avec le `total` et le `carried_over` (impayé reporté). La commande `rent:rollover`, planifiée le 1er de chaque mois à 00:05, ouvre la période du mois et reporte l'impayé du mois précédent.
- **Solde** (`RentBalance`) : `dû = total + report` ; `payé = somme des paiements SUCCESS` ; `reste = max(0, dû - payé)`. Un paiement plus grand que le reste est refusé (422).

## Paiements (mode simulé)

`PAYMENT_DRIVER=fake` (défaut). Le flux :

1. `POST /payments` crée un paiement `PENDING` et répond `{ payment: { id, status, amount, operator } }`.
2. Le mobile relit `GET /payments/{id}`. Le serveur, en mode simulé, règle le paiement à la première lecture **après** `PAYMENT_FAKE_DELAY` secondes (4 par défaut) : `SUCCESS`, sauf si le numéro finit par `00` (alors `FAILED`).
3. Seulement à `SUCCESS` le loyer du mois change (`paid`, `remaining`, `status`) et le reçu devient disponible. Avant, le reçu répond 400.
4. `POST /payments/webhook` est le point d'entrée prévu pour un vrai opérateur.

Conséquence pour l'écran B3 à venir : il doit **interroger l'API en boucle** jusqu'à `SUCCESS` ou `FAILED`, avec un nombre maximal d'essais.

## Images

`POST /uploads` (multipart, champ `file` + `kind`) passe par `ImageStorage` : si `CLOUDINARY_URL` est rempli, envoi vers Cloudinary via `CloudinaryService` (échec : 502) ; sinon enregistrement sur le disque local. Le paquet `cloudinary/cloudinary_php` doit être installé (`composer install`).

## Les tests

- `php artisan test` : 250 tests, base SQLite **en mémoire** (`phpunit.xml`), refaite à chaque test.
- `tests/Support/BuildsData.php` : aides `user($role)`, `actingAsRole($role)`, `housing(...)`. `Sanctum::actingAs($user)` simule un utilisateur connecté sans passer par le login.
- Un test = un comportement : `test_role_matrix` vérifie toutes les routes protégées pour chaque rôle ; `SeederIntegrityTest` vérifie que les données de démonstration sont cohérentes.

## Lancer le backend

```
cd backend
composer install
cp .env.example .env        # puis renseigner DB_*, CLOUDINARY_URL
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Téléphone en USB : `adb reverse tcp:8000 tcp:8000`, l'app vise alors `http://127.0.0.1:8000/api`.

## À retenir en cinq phrases

1. Une requête traverse : route, middlewares (jeton, compte actif, rôle), contrôleur, modèle, JSON.
2. Le rôle et le compte actif sont vérifiés côté serveur, toujours ; l'app n'est qu'un confort.
3. Toute erreur est `{ message, errors? }` en français : le mobile en dépend.
4. Logement = le bien et son code ; annonce = sa publicité ; location = le lien locataire-logement avec un statut.
5. Le solde d'un mois = dû (loyer + report) moins les paiements réussis ; l'impayé se reporte via `rent:rollover`.
