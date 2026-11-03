# Les parcours suivis à travers le code

Un parcours = une action de l'utilisateur, suivie fichier par fichier jusqu'à la base de données et retour. Pour chacun : lisez, puis **refaites le trajet vous-même** en posant un `debugPrint` à chaque étape ou en regardant les logs `[api] ...` du terminal.

Notation : `M:` mobile (`mobile/lib/...`), `B:` backend (`backend/...`).

---

## 1. Le lancement de l'application

```
M: main.dart                              GetStorage.init, initializeDependencies, runApp
M: app.dart                               GetMaterialApp, initialRoute = AppPages.initial
M: presentation/routes/app_pages.dart     AppPages.initial : splash (ou menu dev en faux mode)
M: features/splash/splash_controller.dart onReady → _route()
```

`_route()` attend 2,6 s (l'animation), puis décide :

1. onboarding jamais terminé (`AppStorage.onboardingDone`) → `/onboarding` ;
2. session en cache → **revalidée** par `AuthRepository.refreshSession()` (`GET /auth/me`), avec un délai maximal de 5 s : si le réseau est coupé, on garde le cache ; si le jeton est rejeté (401), la session est effacée ;
3. puis l'accueil du rôle (`TENANT` → `/rent-tracking`, `OWNER` → `/owner/dashboard`, `ADMIN` → `/admin`) ;
4. sinon le catalogue public (`/listings`).

À retenir : le lancement ne reste **jamais bloqué** (délai + `catchError`).

## 2. Se connecter

```
M: features/auth/login_page.dart          _submit() : valide le Form, appelle controller.login
M: features/auth/auth_controller.dart     login() : état loading, appelle le repository, navigue
M: data/repo/auth_repository.dart         login() : service.login, puis _saveSessionFrom(json)
M: data/remote/services/auth_service.dart _api.post('/auth/login', body: {...})
M: data/remote/api_client.dart            _send → _dispatch → _handle (jeton, délai, erreurs)
        ── HTTP : POST /api/auth/login ──────────────────────────────
B: routes/api.php                         Route::post('/login', [AuthController::class, 'login'])
B: app/Http/Controllers/Api/AuthController.php  login()
B: app/Models/User.php                    User::where('email', ...), Hash::check
B: app/Http/Resources/UserResource.php    forme du JSON de l'utilisateur
        ── réponse 200 { token, user } ──────────────────────────────
M: data/cache/auth_storage.dart           saveSession(token, user) : jeton + rôle + profil
M: auth_controller.dart                   Get.offAllNamed(accueil du rôle)
```

Les trois issues d'erreur, à connaître par cœur :

| Serveur | `ApiClient` lève | Ce que voit l'utilisateur |
|---|---|---|
| 401 « Email ou mot de passe incorrect. » | `UnauthorizedException(message)` | ce message, sous le formulaire |
| 422 (e-mail mal formé) | `ValidationException` | premier message de `errors` |
| pas de réseau | `NetworkException` | « Pas de connexion internet. » |

## 3. S'inscrire, puis l'onboarding

```
M: register_page.dart → AuthController.register   (register_controller.dart est un fichier vide)
M: auth_repository.register   : envoie nom et prénoms (si l'un est vide, copie l'autre)
M: auth_service.register      : POST /auth/register
B: RegisterRequest            : valide (e-mail unique, téléphone ^01[0-9]{8}$, mot de passe ≥ 8, rôle TENANT|OWNER)
B: AuthController::register   : Hash::make, createToken, 201 { token, user }
M: AuthController             : TENANT → /onboarding/ville ; OWNER → /onboarding/proprietaire
```

Onboarding locataire : ville → type → budget, enregistrés dans `AppStorage.preferences` (`SearchPreferences`) ; elles filtrent ensuite le fil d'annonces (`ListingsController`).

## 4. Rejoindre un logement avec le code (écran B1)

```
M: features/rental/join_housing_page.dart       le champ de code (CodeInput)
M: features/rental/join_housing_controller.dart onCodeChanged(code) → lookup ; confirm() → join
M: data/repo/rental_repository.dart             lookup / join
M: data/remote/services/rental_service.dart     GET /housings/lookup?code=  ;  POST /rentals/join
B: HousingController::lookup                    public : aperçu du logement (titre, loyer, propriétaire vérifié ?)
B: RentalController::join                       409 si déjà une location, 404 si code inconnu, 409 si occupé,
                                                sinon Rental PENDING (201)
M: join_housing_controller.confirm              Get.offAllNamed('/rent-tracking')
```

Le détail qui montre la maturité du code : `_lookupToken`. L'utilisateur tape le code lettre par lettre ; chaque frappe complète lance une recherche. Si deux recherches se croisent, la plus ancienne peut répondre **après** la plus récente. Le contrôleur incrémente un jeton à chaque recherche et **ignore** toute réponse dont le jeton n'est plus le dernier :

```dart
final token = ++_lookupToken;
final found = await _repository.lookup(code);
if (token != _lookupToken) return;     // une recherche plus récente est partie : on jette celle-ci
```

## 5. Le propriétaire accepte la demande

```
M: features/owner_dashboard/owner_dashboard_view.dart   section « Demandes de location » (AdminActionCard)
M: owner_dashboard_controller.dart                      acceptRequest(r) : verrou busyRequests, appelle le repository
M: data/repo/owner_dashboard_repository.dart            accept(rentalId)
M: data/remote/services/owner_dashboard_service.dart    POST /owner/rentals/{id}/accept
B: routes/api.php                                       groupe owner : auth:sanctum + role:OWNER
B: OwnerDashboardController::acceptRental               403 si ce n'est pas MON logement ; 409 si pas PENDING ;
                                                        409 si le logement est déjà occupé ; sinon ACTIVE
```

Côté locataire, la page « Mon loyer » relit `GET /me/situation` (tirer pour actualiser) et passe de « en attente » à « location active » avec le loyer du mois.

## 6. Le locataire consulte son loyer

```
M: rent_tracking_page.dart  ← Obx sur controller.loadStatus / controller.phase
M: rent_tracking_controller.dart  load() : repository.load(), puis phase / loadStatus
M: data/repo/tenant_rent_repository.dart  situation → (si ACTIVE) currentRent + payments → cache
M: rental_service.dart      GET /me/situation, /me/rent, /me/payments?per_page=100
B: RentalController::situation, currentRent ; PaymentController::myPayments
B: app/Services/RentBalance.php  due, paid, remaining
```

Hors connexion : `TenantRentRepository.load()` attrape `NetworkException`, relit le cache (`AppStorage`) et marque `fromCache`. L'écran affiche alors le bandeau « hors connexion ».

## 7. Publier une annonce

```
M: features/listings/listing_form_page.dart        formulaire (titre, loyer, pièces, photos, logement obligatoire)
M: listing_form_controller.dart                    charge les logements du propriétaire, valide, appelle publish
M: data/repo/owner_announcement_repository.dart    publish() :
      1. pour chaque photo : POST /uploads (kind=announcement_photo) → URL
      2. POST /announcements { housing_id, title, type, rent, ..., photos:[URL...] } → 201, id
      3. POST /announcements/{id}/publish
B: UploadController → ImageStorage → CloudinaryService (ou disque local)
B: AnnouncementController::store   DRAFT, housing_id vérifié (doit être MON logement)
B: AnnouncementController::publish PUBLISHED, published_at
```

Si l'étape 3 échoue, l'annonce reste `DRAFT` côté serveur et l'erreur est relancée : rien n'est perdu.

## 8. Un signalement arrive chez l'administrateur

**Attention : la création d'un signalement n'existe pas dans l'application mobile.** `data/remote/services/report_service.dart` et `data/repo/report_repository.dart` sont des fichiers vides, et aucun écran (détail d'annonce compris) n'envoie de signalement. Le backend, lui, est prêt (`POST /announcements/{id}/reports`, motif obligatoire). Aujourd'hui l'administrateur ne voit donc que des signalements créés par l'API directement (jeu de données de démonstration, ou appel manuel).

La partie qui existe, côté administrateur :

```
M: features/admin/admin_controller.load                   GET /admin/reports (tableau nu, enveloppé par ApiClient)
M: ReportGroup.from(reports)                              regroupe par annonce
M: AdminController.removeAnnouncement(group)              pour CHAQUE signalement du groupe :
                                                          POST /admin/reports/{id}/resolve { action: REMOVE_ANNOUNCEMENT }
B: AdminController::resolveReport                         annonce → CANCELED, signalement → RESOLVED
```

La carte disparaît de l'écran **au fil des confirmations** du serveur ; si une requête échoue au milieu d'un groupe, le reste reste visible et le bouton est déverrouillé.

Bon exercice de création (une fois le reste maîtrisé) : ajouter le bouton « Signaler » du détail d'annonce, avec `ReportService`, `ReportRepository` et un test.

## 9. Se déconnecter

```
M: profile_page.dart     _confirmLogout : prend le contrôleur AVANT le dialogue, puis profile.logout()
M: profile_controller    logout() : verrou isLoggingOut, repository.logout(), Get.offAllNamed('/login')
M: auth_repository       logout() : service.logout() (ignoré si pas de réseau), puis storage.clear()
B: AuthController::logout  supprime LE jeton courant → il ne marche plus
```

À retenir : même si le serveur est injoignable, la session **locale** est effacée. Et la ligne « prendre le contrôleur avant le dialogue » est le correctif d'un bug réel (voir [02](02-architecture-mobile.md)).

## 10. Ce qui n'existe pas encore : payer

L'écran B3 devra, dans cet ordre : `POST /payments` (montant, opérateur, numéro) → recevoir `PENDING` → relire `GET /payments/{id}` à intervalle régulier avec un plafond d'essais → `SUCCESS` (ouvrir B4 « Paiement réussi », puis `GET /payments/{id}/receipt`) ou `FAILED` (message, proposer de réessayer). Un numéro finissant par `00` simule l'échec. Tout le backend est prêt et testé ; il manque l'écran, son contrôleur et son repository.
