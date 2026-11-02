# Tests

Deux suites : une pour l'API Laravel (`backend/tests`), une pour l'application Flutter (`mobile/test`). Elles ne dépendent ni de XAMPP ni d'un serveur lancé.

## Back

```bash
cd backend
php artisan test                          # tout
php artisan test --filter=PaymentTest     # une classe
php artisan test --filter=test_webhook    # un test
```

Les tests tournent sur SQLite en mémoire (`phpunit.xml`), base recréée à chaque test (`RefreshDatabase`). Aucun appel réseau : Cloudinary est simulé (`CloudinaryService` remplacé par un mock).

| Fichier | Couvre |
|---|---|
| `Feature/Auth/AuthTest` | Inscription (validation, doublons, e-mail en minuscules, rôle ADMIN refusé), connexion, compte suspendu, déconnexion, mot de passe oublié, messages en français |
| `Feature/Auth/ProfileTest` | Modification du profil et du mot de passe, champs protégés (rôle, e-mail, badge), demande d'identité |
| `Feature/AnnouncementTest` | Fil public (filtres, pagination, plafond de `per_page`), détail, brouillons masqués, création, édition, publication, annulation |
| `Feature/FavoriteAndReportTest` | Favoris (idempotence, privés), signalements (un seul par utilisateur) |
| `Feature/HousingTest` | Création, code logement unique, périmètre propriétaire, `lookup` public sans fuite de données |
| `Feature/RentalTest` | Rejoindre un logement (404, 409), fin de location, loyer du mois (PAID/PARTIAL/LATE/UPCOMING, report) |
| `Feature/PaymentTest` | Création, plafond au solde restant, simulation de l'opérateur, reçu, webhook (secret, idempotence) |
| `Feature/OwnerTest` | Tableau de bord, locataires, accepter/refuser une demande, paiement en espèces |
| `Feature/AdminTest` | Demandes d'identité, signalements, utilisateurs, suspension |
| `Feature/UploadTest` | Upload local, validation, Cloudinary (simulé), échec Cloudinary (502) |
| `Feature/RolloverCommandTest` | `rent:rollover` : report des impayés, idempotence, planification |
| `Feature/RoleMiddlewareTest` | Matrice route × rôle, et toutes les routes protégées refusent un visiteur |
| `Feature/SeederIntegrityTest` | Les comptes et codes de `02-installation-locale.md` existent et fonctionnent |
| `Unit/DomainTest` | Valeurs d'enum figées (contrat JSON), format du code logement, calcul du solde |

Fabriques de données dans `tests/Support/BuildsData.php` : `user()`, `actingAsRole()`, `housing()`, `rental()`, `payment()`, `activeSetup()`.

### Écrire un test

- Un test = un comportement, nommé par ce qu'il garantit (`test_other_owner_cannot_update_publish_or_cancel`).
- Tester le comportement **voulu** d'après le contrat, pas ce que fait le code : un test qui échoue révèle un défaut du code.
- Pour une règle d'accès, tester les deux côtés : le bon rôle passe, les autres sont refusés.
- Le temps se fige avec `$this->travelTo(...)` ; ne jamais dépendre de la date du jour.

## Mobile

```bash
cd mobile
flutter test                                   # tout
flutter test test/data/repositories_test.dart  # un fichier
flutter test --plain-name "confirm"            # par nom
```

| Fichier | Couvre |
|---|---|
| `test/core/api_client_test.dart` | `ApiClient` : en-têtes, jeton Bearer, requête, 401 (avec ou sans jeton), 422, 409/403/404, 500, réponse HTML, réseau coupé, délai dépassé, upload |
| `test/core/utils_test.dart` | Validateurs (téléphone `01…`, e-mail, mot de passe), montants FCFA, dates, URL Cloudinary |
| `test/domain/models_test.dart` | Modèles (valeurs manquantes ou inattendues), préférences de recherche, enums alignés sur l'API |
| `test/data/repositories_test.dart` | Dépôts de bout en bout (dépôt → service → client HTTP → faux serveur) : auth, session, annonces, B1, identité |
| `test/presentation/controllers_test.dart` | Contrôleurs : fil et favoris, détail, B1, connexion/inscription, navigation, doubles appuis |
| `test/api_contract_test.dart` | Contrat de l'API et faux services (mode `USE_FAKE_API`) |

Outils communs dans `test/support/fakes.dart` :

- `FakeServer` : faux serveur HTTP. `server.on('GET', '/announcements', body: {...})`, puis `server.client` est un vrai `ApiClient`. `server.seen` liste les requêtes reçues.
- `MemoryAuthStorage`, `MemoryAppStorage` : stockages en mémoire, sans disque.
- `userJson`, `announcementJson(n)` : réponses types du contrat.

Les tests qui affichent un snackbar passent par `withApp(...)` (dans `controllers_test.dart`), qui fournit l'`Overlay` d'une vraie app GetX.

## Ce qui n'est pas testé

- Les écrans (widgets) : à vérifier à la main sur l'émulateur, back lancé.
- KKiaPay : le paiement est simulé (`PAYMENT_DRIVER=fake`).
- Cloudinary réel : seulement des réponses simulées.
- MySQL : les tests tournent sur SQLite. Lancer `php artisan migrate:fresh --seed` sur XAMPP reste le contrôle de la base réelle.
