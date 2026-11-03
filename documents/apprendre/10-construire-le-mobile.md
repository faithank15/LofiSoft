# Reconstruire le mobile, étape par étape

Chaque étape donne : ce qu'on construit, **dans quel ordre écrire les fichiers**, ce qu'il faut comprendre, les pièges déjà rencontrés, et quoi vérifier. Les noms de fichiers renvoient à la [carte du code](01-carte-du-code.md).

Règle d'or de l'ordre : **on écrit toujours de l'intérieur vers l'extérieur**. D'abord ce qui ne dépend de rien (erreurs, modèles), puis la couche qui les utilise (client, services, repository), puis le contrôleur, enfin la page. À chaque palier, un test peut tourner.

---

## Étape 0 — Le projet vide

```
flutter create mobile
```

Dépendances (`pubspec.yaml`) et pourquoi :

| Paquet | Pour |
|---|---|
| `get` | état réactif, injection, navigation (GetX) |
| `get_storage` | stockage clé-valeur local (session, préférences, cache) |
| `http` | appels HTTP (et `MockClient` pour les tests) |
| `image_picker` | photos d'annonce, pièce d'identité |
| `url_launcher` | « Appeler » le propriétaire |
| `share_plus` | partager le code d'un logement |
| `cached_network_image`, `flutter_svg` | images distantes, illustrations |

Ajouter la police (dossier `assets/fonts`, déclarée dans `pubspec.yaml`) : les tests de rendu la chargent aussi (`test/support/app_fonts.dart`).

Vérifier : `flutter run` affiche l'écran de démonstration.

---

## Étape 1 — Le thème et les constantes (`core/`)

Fichiers, dans l'ordre : `core/theme/app_colors.dart`, `app_spacing.dart` (avec `AppSizes`), `app_radius.dart`, `app_shadows.dart`, `app_text_styles.dart`, `app_theme.dart`, puis `core/constants/app_config.dart`.

À comprendre :

- Un thème = des **constantes nommées**. Aucune page n'écrit `Color(0xFF...)` ni `EdgeInsets.all(13)` : elle prend `AppColors.green`, `AppSpacing.lg`. Changer la charte = changer un fichier.
- `AppConfig` lit des valeurs **de compilation** :

```dart
static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000/api');
static const useFakeApi = bool.fromEnvironment('USE_FAKE_API');
```

`useFakeApi` étant une constante, le compilateur retire le faux mode de l'application livrée.

Piège : une IP écrite en dur (celle d'un coéquipier) est restée dans le code une fois. Le défaut est `127.0.0.1`, et le téléphone USB y accède par `adb reverse tcp:8000 tcp:8000`.

---

## Étape 2 — Erreurs, JSON sûr, modèles du domaine

Fichiers : `core/errors/app_exception.dart`, `core/utils/json_utils.dart`, `domain/models/enums.dart`, `domain/models/user_model.dart`.

### Les erreurs typées

```dart
sealed class AppException implements Exception { const AppException(this.message); final String message; }
class NetworkException extends AppException { const NetworkException([super.message = 'Pas de connexion internet.']); }
class UnauthorizedException ...   class ValidationException ...   class ServerException ...
```

`sealed` : le compilateur sait qu'il n'y a que ces quatre cas, donc un `switch` oubliant un cas est signalé. Les couches basses **lèvent**, les contrôleurs **attrapent** et affichent `message`.

### Le JSON sûr

```dart
Map<String, dynamic> asJsonMap(Object? value)   // une Map, ou une Map vide
List<dynamic> asJsonList(Object? value)         // une List, ou une liste vide
```

Pourquoi : le serveur peut renvoyer `null`, un champ manquant, un autre type. Ces deux fonctions évitent les plantages `type 'Null' is not a subtype of...`.

### Un modèle tolérant

`UserModel.fromJson` lit chaque champ avec une valeur par défaut (`'${json['nom'] ?? ''}'`), accepte `TENANT` / `tenant` / `PROPRIÉTAIRE` pour le rôle, et `toJson` écrit ce que `fromJson` relit (le cache de session en dépend). Récemment ajouté : `identityVerified`, lu depuis `identity_verified`.

**Exercice** : `mobile-user-model`. Test : `test/domain/models_test.dart`.

---

## Étape 3 — Le client HTTP unique (`data/remote/api_client.dart`)

C'est le fichier le plus important du socle. Il fait **cinq** choses et pas une de plus :

1. ajoute `Authorization: Bearer <jeton>` si une session existe ;
2. applique le délai maximal (`AppConfig.timeout`, 20 s) ;
3. transforme les échecs réseau en `NetworkException` (`SocketException`, `TimeoutException`, `ClientException`) ;
4. transforme les codes HTTP en exceptions typées :

| Code | Exception | Message |
|---|---|---|
| 2xx | rien, renvoie la Map | |
| 401 avec jeton | `UnauthorizedException` | session effacée (`_auth.clear()`) |
| 401 sans jeton | `UnauthorizedException` | message du serveur (« Email ou mot de passe incorrect. ») |
| 400, 422 | `ValidationException` | premier message de `errors`, sinon `message` |
| ≥ 500 | `ServerException` | générique |
| autre | `ServerException` | message du serveur |

5. **enveloppe** une réponse qui n'est pas un objet : une liste JSON devient `{'data': liste}`.

Ce qu'il **ne fait jamais** : naviguer. Sur 401 il efface la session et lève ; ce sont les contrôleurs et les gardes qui réagissent.

Il reçoit un `http.Client` optionnel : en test, on lui donne un `MockClient`.

**Exercice** : `mobile-api-client`. Test : `test/core/api_client_test.dart`.

Aussi dans cette étape, côté stockage : `data/cache/auth_storage.dart` (jeton, rôle, profil ; `hasSession` = jeton non vide **et** rôle) et `data/cache/app_storage.dart` (onboarding terminé, préférences de recherche, cache JSON pour le hors-ligne).

Puis le point de composition, `di/injector.dart` :

```dart
Future<void> initializeDependencies() async {
  final authStorage = Get.put(AuthStorage(), permanent: true);
  Get.put(AppStorage(), permanent: true);
  Get.put(ApiClient(authStorage: authStorage), permanent: true);
}
```

et `main.dart` : `WidgetsFlutterBinding.ensureInitialized()`, `GetStorage.init()`, `initializeDependencies()`, `runApp`. `permanent: true` : ces trois objets vivent toute la vie de l'app et ne sont jamais détruits.

---

## Étape 4 — Routes, pages, gardes

Fichiers : `presentation/routes/app_routes.dart`, `app_pages.dart`, `auth_middleware.dart`, `role_middleware.dart`, puis `app.dart`.

- `AppRoutes` : une constante par écran. Les identifiants vont dans le chemin (`'/owner/properties/detail/:id'`).
- `AppPages.pages` : une liste de `GetPage(name, page, binding, middlewares)`. `AppPages.initial` vaut le menu de développement en faux mode, le splash sinon.
- **Les gardes** (`GetMiddleware`) : la méthode `redirect(route)` renvoie `null` pour laisser passer, ou un `RouteSettings(name: ...)` pour rediriger.

```dart
class AuthMiddleware extends GetMiddleware {
  @override int? get priority => 1;
  @override RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthStorage>()) return null;
    if (Get.find<AuthStorage>().hasSession) return null;
    return const RouteSettings(name: AppRoutes.login);
  }
}
```

`RoleMiddleware(Set<UserRole>)` laisse passer un rôle autorisé, sinon renvoie vers l'accueil **du rôle de l'utilisateur** (`homeRouteFor`). La priorité fixe l'ordre : `AuthMiddleware` (1) avant `RoleMiddleware` (2).

Dans `app_pages.dart`, des listes réutilisables : `_signedIn`, `_tenant`, `_owner`, `_admin`, appliquées aux routes protégées.

À comprendre : ces gardes sont du **confort**. Leur absence ne change pas la sécurité (le serveur refuse). Le test `route_guards_test.dart` vérifie chaque cas.

**Exercice** : `mobile-garde`.

---

## Étape 5 — Une fonctionnalité de bout en bout : la connexion

C'est l'étape où tout se met en place. Ordre d'écriture :

| # | Fichier | Ce qu'il contient |
|---|---|---|
| 1 | `data/remote/services/auth_service.dart` | `login`, `register`, `me`, `forgotPassword`, `logout`, `submitIdentity` : une ligne chacun, `_api.post('/auth/login', body: {...})` |
| 2 | `data/remote/fakes/fake_auth_service.dart` | hérite de `AuthService`, répond sans réseau (comptes `@lofi.bj`, mot de passe `Test1234`) |
| 3 | `data/repo/auth_repository.dart` | `login` (appelle le service, **enregistre la session**), `register`, `refreshSession`, `logout`, `forgotPassword` |
| 4 | `presentation/features/auth/auth_controller.dart` | `status`, `errorMessage`, `login(...)`, `register(...)`, `sendResetLink(...)` |
| 5 | `auth_binding.dart` | choisit vrai ou faux service, fournit repository et contrôleur |
| 6 | `login_page.dart` | formulaire, `TextEditingController` dans la page |
| 7 | route dans `app_pages.dart` | `GetPage(name: AppRoutes.login, page: ..., binding: AuthBinding())` |

### Ce que fait `AuthController.login`

```dart
if (isLoading) return;                                 // un double appui est ignoré
status.value = LoadStatus.loading;
errorMessage.value = null;
try {
  final user = await _repository.login(email: email.trim(), password: password);
  status.value = LoadStatus.loaded;
  Get.offAllNamed(_homeRouteFor(user.role));          // vide la pile : retour impossible vers le login
} on AppException catch (e) {
  _fail(e.message);                                   // message prêt à afficher
} catch (_) {
  _fail('Une erreur inattendue est survenue.');       // dernier filet : aucune erreur brute à l'écran
}
```

### Ce que fait la page

- `StatefulWidget` : elle possède `_email` et `_password` (`TextEditingController`), créés dans l'état, **libérés dans `dispose()`**.
- `Form` + `validator` (`Validators.email`, `passwordPresent`) : la validation de saisie est faite **avant** d'appeler le contrôleur.
- `Obx` autour de ce qui change (mot de passe visible, message d'erreur, bouton en chargement).

### Les deux détails qui font la robustesse

- Le repository **enregistre la session** (`AuthStorage.saveSession`) : le contrôleur n'a pas à y penser.
- Ouvrir la page de connexion **ferme toute session restante** (`AuthController.onInit` → `endSessionIfAny`) : on repart toujours de zéro.

### Le mot de passe oublié

`forgot_password_page.dart` suit le même modèle : un seul champ, `controller.sendResetLink(...)`, puis un écran de confirmation. Le serveur répond pareil que l'adresse existe ou non (on ne révèle pas quels comptes existent), d'où le message neutre « Si cette adresse correspond à un compte... ».

**Exercice** : `mobile-auth`. Tests : `test/data/repositories_test.dart`, `test/presentation/controllers_test.dart`.

---

## Étape 6 — Côté locataire : Mon loyer

Fichiers : `domain/models/tenant_rent_model.dart`, `data/repo/tenant_rent_repository.dart`, `presentation/features/rent_tracking/`.

Le scénario : l'écran doit savoir **où en est** le locataire et s'adapter.

| Phase | Source | Écran |
|---|---|---|
| aucune location | `GET /me/situation` → `NONE` | bouton « Rejoindre mon logement » (écran B1) |
| demande en attente | `PENDING` | « En attente du propriétaire » |
| location active | `ACTIVE` | loyer du mois (`GET /me/rent`), historique (`GET /me/payments`) |

Le repository `TenantRentRepository.load()` :

1. appelle `situation()` ;
2. si `ACTIVE`, appelle aussi `currentRent()` et `payments()` ;
3. **sauvegarde tout** dans le cache (`AppStorage.saveJson('tenant_rent', ...)`) ;
4. si le réseau est coupé (`NetworkException`) : relit le cache et marque le résultat `fromCache: true`.

C'est ainsi que l'écran reste utile hors connexion : le contrôleur affiche alors un bandeau « hors connexion » avec la date de la dernière mise à jour.

Piège historique : cet écran affichait d'abord des **données de démonstration écrites en dur**, ce qui interdit par la règle « pas de données factices dans les vrais repositories ». Les fausses données vivent seulement dans `FakeRentalService`.

**Exercice** : `mobile-loyer`. Test : `test/tenant/tenant_rent_test.dart`.

**Manquant** : B3 « Payer » et B4 « Paiement réussi » (dossier `payment/` vide). Voir la fin de [03-architecture-backend.md](03-architecture-backend.md) pour le contrat à respecter.

---

## Étape 7 — Côté propriétaire

Fichiers : `owner_dashboard/`, `owner_properties/`, `listings/listing_form_*`, `data/repo/owner_*`.

Le parcours **logique** d'un propriétaire, et qui fait quoi :

1. **Ajouter un logement** : `housing_create_page.dart` → `POST /housings`. Le serveur renvoie un **code** (`ABC-DEF`) que le propriétaire donne à son locataire.
2. Le locataire saisit le code (B1) → location `PENDING`.
3. **Accueil propriétaire** : section « Demandes de location » (`GET /owner/requests`). Boutons Accepter / Refuser → `POST /owner/rentals/{id}/accept|reject`.
4. **Créer une annonce** (`listing_form_page.dart`) : **à partir d'un logement existant** (champ obligatoire). Le repository `OwnerAnnouncementRepository.publish` envoie les photos une à une (`POST /uploads`), crée l'annonce (`POST /announcements`), puis la publie (`POST .../publish`).
5. **Mettre fin à la location** : `POST /rentals/{id}/end`.

Deux idées à retenir :

- **Un contrôleur qui échoue partiellement.** `OwnerDashboardController` charge le tableau de bord (obligatoire) et les demandes (facultatif : `_loadRequests` tolère l'échec). Un écran ne doit pas tomber entièrement parce qu'une section secondaire échoue.
- **Les actions longues ont un verrou** (`busyRequests`, `busy`) : un bouton pressé deux fois n'envoie qu'une requête.

**Exercice** : `mobile-demandes`. Test : `test/owner/requests_test.dart`.

---

## Étape 8 — Administration et profil

Fichiers : `features/admin/*`, `features/profile/*`, `data/repo/admin_repository.dart`, `domain/models/admin_model.dart`.

- **D1 Signalements** : `ReportGroup.from(reports)` regroupe les signalements **par annonce**. Supprimer l'annonce ou l'ignorer **clôt tous** ses signalements : sinon la carte reviendrait au prochain chargement.
- **D2 Vérifications** : valider ou refuser (avec motif obligatoire) une pièce d'identité. Valider passe le propriétaire à « Vérifié » (`identity_verified`).
- **Utilisateurs** : suspendre / réactiver. Un administrateur ne peut pas se suspendre lui-même (le serveur refuse aussi).
- `AdminShell` : squelette commun des trois écrans (titre, liste tirable pour actualiser, états chargement / erreur / vide, barre du bas).
- **Profil** (`ProfileController`) : affiche le profil du cache tout de suite, le remplace par celui du serveur, se déconnecte (un double appui est ignoré).

À comprendre : `AdminController.load` fait **trois** appels (signalements, identités, comptes). Une carte retirée l'est **dès que le serveur confirme**, pas avant : en cas d'échec au milieu d'un groupe, ce qui n'a pas été traité reste visible.

**Exercice** : `mobile-admin`. Test : `test/admin/admin_test.dart`.

---

## Étape 9 — Les tests

Principe : tester la **vraie** chaîne (contrôleur → repository → service → `ApiClient`) contre un **faux serveur**, pas contre des `FakeService`.

```dart
final server = FakeServer();                       // test/support/fakes.dart, basé sur MockClient
server.on('GET', '/admin/users', body: {'data': [...]});
final c = AdminController(repository: AdminRepository(AdminService(server.client)));
await c.load();
expect(c.users.length, 2);
expect(server.last.path, '/api/admin/users');       // le chemin contient le préfixe /api
```

- `MemoryAuthStorage` (aussi dans `fakes.dart`) remplace le stockage disque.
- `Get.testMode = true; Get.reset();` dans `setUp` : chaque test repart d'un GetX propre.
- Les tests qui **naviguent** ou affichent une `snackbar` utilisent `testWidgets` avec un `GetMaterialApp`, et `tester.runAsync` pour les appels asynchrones.
- `bindings_test.dart` construit les bindings et leurs contrôleurs. Limite honnête : il n'a pas détecté le bug `AuthStorage?` du lancement ; seul le correctif du code protège. Un test ne prouve que ce qu'il vérifie.
- Les tests « golden » comparent des captures d'écran de l'onboarding (6 sont ignorés par défaut).

Lancer : `flutter test` (347 tests). Pour un seul fichier : `flutter test test/admin/admin_test.dart`.

**Exercice final** : prenez une page sans test (la page « Utilisateurs » admin, par exemple) et écrivez un test de contrôleur qui échoue d'abord, puis passe.
