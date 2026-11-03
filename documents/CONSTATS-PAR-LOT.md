# Constats de la phase de test, par lot

Date : 3 novembre 2026. Tests faits : suite automatique (347 tests mobile, 250 tests backend),
20 testeurs robots sur l'app compilée en web (mode factice), et un scénario de bout en bout
de 203 vérifications sur le vrai backend (Laravel + MySQL), repassé à 203 sur 203 après corrections.

Gravité : **Bloquant** (une action principale est impossible), **Grave** (erreur ou donnée fausse),
**Gênant** (incohérence, validation manquante), **Mineur** (propreté).

Les robots ne remplacent pas un test à la main sur téléphone : appel, GPS, caméra, partage
ne sont pas vérifiés.

## Lot 1 — Annonces (A1, A3, A4) et filtres (A2)
Responsable : à renseigner.

| Gravité | Constat | Où |
|---|---|---|
| Gênant | Pas de page de filtres dédiée (A2). Les filtres passent uniquement par les préférences d'onboarding. | `listings/` |
| **Grave** | Aucun écran ne permet de signaler une annonce : `report_service.dart` et `report_repository.dart` sont vides, le détail d'annonce n'a pas de bouton « Signaler ». Le backend (`POST /announcements/{id}/reports`) est prêt. Sans cela, l'écran D1 des signalements ne reçoit jamais de données réelles. | `listing_details_page.dart`, `data/remote/services/report_service.dart` |
| Gênant | Dans le détail d'une annonce, « Itinéraire », « Appeler » et « WhatsApp » affichent seulement une bulle « Bientôt ». | `listing_details_page.dart` lignes 213, 345, 365 |
| Mineur | `app_network_image.dart` : sous-tirets inutiles (ligne 56). `rent_gauge.dart` : import `dart:ui` inutile. `receipt_summary.dart` : concaténation à remplacer par une interpolation. | `components/` |

Vérifié sur le backend : la liste filtre bien par ville, type, prix min et prix max, plafonne `per_page`, et ne plante pas avec des filtres absurdes.

## Lots 3 et 4 — Onboarding (E1 à E7)
Responsable : à renseigner.

| Gravité | Constat | Où |
|---|---|---|
| Gênant | Une exception JavaScript est apparue sur « Où voulez-vous habiter ? » après des clics rapides sur une ville, puis un double clic sur « Retour ». Le message ne donne pas de détail. À reproduire à la main sur l'appareil. | `/onboarding/ville` |

Reproduction : choisir une ville, double-cliquer sur « Retour », revenir sur l'écran, recliquer vite sur plusieurs villes. Vu par 1 testeur sur 20, mode mobile.

## Lot 5 — Locataire : paiement, loyer, historique (B2, B3, B4, B5, B6)
Responsable : à renseigner.

| Gravité | Constat | Où |
|---|---|---|
| **Bloquant** | B3 « Payer » et B4 « Paiement réussi » n'existent pas. Les 4 fichiers de `features/payment/` sont vides (0 ligne) et la route `/payment` n'est enregistrée dans aucune page. Le bouton « Payer » de Mon loyer mène donc à une page inconnue. | `payment/*.dart`, `rent_tracking_page.dart` ligne 108 |
| Gênant | À prévoir pour B3 : le backend crée le paiement en `PENDING`, et le statut ne change que lorsqu'on relit `GET /payments/{id}` après le délai (4 s en mode simulé). L'écran doit donc interroger l'API en boucle, avec un plafond de tentatives. | `PaymentController::settleSimulated` |
| Gênant | Contrat à respecter : `POST /payments` répond `{ payment: { id, status, amount, operator } }` (clé `payment`, pas `data`). Le montant ne peut pas dépasser le solde restant (422). Un numéro finissant par `00` donne `FAILED`. | backend |
| Gênant | WhatsApp dans Mon loyer : bulle « Bientôt ». | `rent_tracking_page.dart` ligne 178 |

Déjà fait par ailleurs : Mon loyer est branché sur l'API (situation, loyer du mois, historique), avec les états aucune location, demande en attente et location active.

## Lot 7 — Propriétaire : accueil et locataires (C1, C7)
Responsable : à renseigner.

| Gravité | Constat | Où |
|---|---|---|
| Mineur | Plusieurs actions de l'accueil affichent « Bientôt ». | `owner_dashboard_view.dart` ligne 48 |

Vérifié sur le backend : tableau de bord, liste et détail des locataires, relance et paiement manuel, avec refus (403/404) pour un autre propriétaire.

## Lot 8 — Propriétaire : logements, annonces, locataires (C2, C5, C6)
Responsable : à renseigner.

| Gravité | Constat | Où |
|---|---|---|
| **Grave** | Écran C6 « Ajouter un locataire » : quand aucun logement n'est présélectionné, le formulaire est rempli avec des valeurs de démonstration écrites en dur (loyer 350 000, caution 700 000) qui ne correspondent pas au logement affiché. La **date de début est toujours « 01/03/2026 »**, même avec un logement choisi. Vu sur le TECNO. | `property_form_page.dart` lignes 63 à 68 (`_syncFieldsWithHousing`) |
| Gênant | La liste des logements marquait tous les logements « Libre », même celui d'un locataire actif (le backend n'envoyait pas `active_rental` dans la liste). | corrigé côté backend (`HousingController::index`) |
| Gênant | Variable `success` inutilisée (avertissement d'analyse). | `property_detail_page.dart` ligne 96 |
| Mineur | Imports inutilisés `app_radius.dart` et `app_shadows.dart`. | `property_list_page.dart` lignes 5 et 6 |
| Mineur | `Share` est déprécié, à remplacer par `SharePlus.instance.share()`. | `property_detail_page.dart` ligne 44, `property_form_page.dart` ligne 183 |
| Mineur | Sous-tirets inutiles. | `property_form_page.dart` ligne 135 |

## Lot 2 — Entrée et connexion (E0, A5, A6, B1) — Faith
| Gravité | Constat | État |
|---|---|---|
| Gênant | « Mot de passe oublié » était une page provisoire. | corrigé : écran réel `forgot_password_page.dart`, appelle `POST /auth/forgot-password` |
| Gênant | Aucun middleware de route : `auth_middleware.dart` et `role_middleware.dart` sont vides. Une URL protégée (`/admin`, `/owner/...`) s'ouvre sans session ni contrôle de rôle côté app. Le backend, lui, refuse bien (401/403). | corrigé : `AuthMiddleware` et `RoleMiddleware` appliqués aux routes locataire, propriétaire, admin et profil. Un mauvais rôle est renvoyé vers sa propre accueil. |
| Mineur | Sur la page de connexion atteinte après une déconnexion, la flèche « Retour » est affichée mais ne fait rien (il n'y a plus de page précédente). Vu sur le TECNO. | `login_page.dart` / `AuthScaffold` |
| Corrigé | Les robots ont trouvé une erreur « not found » en se déconnectant depuis le Profil si l'on quittait la page pendant la confirmation. | corrigé, commit `406aeca` |

## Lot 9 — Administration (D1, D2) et Profil — Faith
| Gravité | Constat | État |
|---|---|---|
| Gênant | L'écran de gestion des utilisateurs (suspendre, réactiver) n'existait pas côté mobile. | corrigé : nouvel onglet « Utilisateurs » (`admin_users_page.dart`, route `/admin/users`) |
| Gênant | Les écrans D1, D2 et Profil sont testés par les tests automatiques et par HTTP, mais pas encore vérifiés visuellement sur le téléphone. | à vérifier sur le TECNO |

## Backend (transversal)
Responsable : à renseigner.

| Gravité | Constat | Où |
|---|---|---|
| **Grave** | `cloudinary/cloudinary_php` est déclaré dans `composer.json` mais absent de `vendor/` sur ce poste. Avec `CLOUDINARY_URL` rempli, tout upload renvoie 502. Corrigé sur ce poste par `composer install` ; **chaque coéquipier doit le lancer après un pull**. | `ImageStorage`, `.env` |
| Gênant | `GET /auth/me` ne renvoyait pas `identity_verified`. | corrigé : `UserResource` (désormais utilisé par register, login, me, update profil et la liste admin). Le Profil affiche « Identité : Vérifiée / Non vérifiée » pour un propriétaire. |
| Gênant | `GET /admin/users` enveloppait sa pagination dans `data` (la liste était dans `data.data`), contrairement aux autres listes. | corrigé : `{ data: [...], meta: {...} }`, paramètre `per_page` |
| Gênant | `RegisterRequest` tolère un seul champ parmi `nom` et `prenoms` et recopie l'autre dans les deux. Une inscription avec seulement un prénom est acceptée avec un nom identique. | `RegisterRequest::prepareForValidation` |
| Mineur | Un champ `nom` contenant du HTML (`<script>`) est enregistré tel quel. Sans danger tant que l'app Flutter n'interprète pas le HTML, mais à échapper si une interface web apparaît. | inscription |
| Mineur | `POST /auth/logout` répond 204 sans corps. Correct, à connaître côté client. | `AuthController::logout` |

Points vérifiés sans défaut côté backend : authentification et jetons, cloisonnement entre rôles et entre propriétaires, création et publication d'annonces, favoris, signalements, demande puis acceptation, rejet et fin de location, paiements (succès, échec, sur-paiement, reçu), identité, administration, et robustesse face aux entrées absurdes (aucune erreur 500).

## Reproduire les tests
- Tests automatiques : `cd mobile && flutter test`, puis `cd backend && php artisan test`.
- Bout en bout sur le vrai backend : lancer MySQL et l'API, puis `python3 .testeurs/e2e_backend.py`. Il crée des comptes `@t.bj` (un `migrate:fresh --seed` les efface).
- Robots : compiler `flutter build web --dart-define=USE_FAKE_API=true`, servir `build/web`, puis lancer le skill `/testeurs`.

## Test sur le téléphone (TECNO CAMON 30, API réelle sur MySQL, Cloudinary installé)

Parcours vérifiés à la main sur l'appareil, avec les requêtes reçues par le serveur : connexion locataire, propriétaire et administrateur ; Mon loyer et historique avec les vraies données ; déconnexion (annuler puis confirmer) ; « Mot de passe oublié » (validation puis `POST /auth/forgot-password`) ; création d'un logement et code ; saisie du code par un autre locataire (aperçu, demande `PENDING`) ; acceptation par le propriétaire ; location active chez le locataire ; D1, D2 et onglet Utilisateurs (suspension confirmée en base, puis réactivation) ; catalogue public, détail d'annonce, favori sans connexion (renvoie à la connexion).

Constat confirmé sur l'appareil : le bouton « Payer mon loyer » ne fait rien (pas de page B3).
Non vérifié sur l'appareil : appel téléphonique, envoi de photo (galerie), gardes de route par lien direct.

## Vérification après l'intégration du lot 6 (3 novembre, soir)

| Constat précédent | État |
|---|---|
| B3 « Payer » et B4 « Paiement réussi » absents (lot 5/6) | **Fait.** Testé contre le vrai backend : création `PENDING`, relecture jusqu'à `SUCCESS`, reçu complet, loyer 0 → 10 000, échec simulé (numéro en `00`), refus d'un montant au-delà du reste. 3 fichiers de tests ajoutés (`test/payment`). |
| Bouton « Signaler » absent | **Fait** (`listing_details_page.dart`, `ReportService`, `ReportRepository`). |
| Itinéraire, Appeler, WhatsApp en « Bientôt » | **Fait** dans le détail d'annonce. Reste « Bientôt » sur l'accueil propriétaire. |
| Exception sur l'onboarding « Où voulez-vous habiter ? » | Plus reproduite par les 20 robots (écran refait avec géolocalisation). |
| Imports et variable inutiles (lot 8) | Imports retirés ; l'analyse passe de 48 à 34 remarques. |
| **C6 : valeurs en dur (350 000, 700 000, date 01/03/2026)** | **Toujours présent** (`property_form_page.dart` lignes 63 à 68). |

Nouveaux constats :

| Gravité | Constat |
|---|---|
| **Grave** | `AppConfig.apiBaseUrl` était repassé à l'adresse d'un coéquipier (`10.140.106.79`) après le merge, ce qui casse la connexion du téléphone en USB. Rétabli à `127.0.0.1`. À ne plus écraser lors des merges : chacun doit passer son adresse par `--dart-define=API_BASE_URL=...`. |
| **Grave** | La permission `INTERNET` n'était déclarée que dans les manifestes `debug` et `profile` : une version `release` n'aurait eu aucun accès réseau. Ajoutée dans `android/app/src/main/AndroidManifest.xml`. |
| Gênant | Le géocodage inverse de « Utiliser ma position » envoie les coordonnées de l'utilisateur à `nominatim.openstreetmap.org` (ou à Google si une clé est fournie). À mentionner dans la politique de confidentialité. |
| Mineur | `FakeReportService` est défini dans `report_service.dart`, alors que les faux services vivent dans `data/remote/fakes/`. |
| Mineur | Un test (`listing_form_test`) a échoué une fois sur trois exécutions complètes (sensible à l'ordre), puis réussi deux fois de suite : à surveiller. |

## Vérification globale finale (4 novembre)

Base testée : `main` après intégration du lot 6, plus les correctifs ci-dessous.

| Contrôle | Résultat |
|---|---|
| Tests mobile | 386 passent, 6 ignorés |
| Tests backend | 251 passent |
| Analyse statique | 34 remarques d'information, aucun avertissement |
| Scénario de bout en bout sur le vrai backend (MySQL) | 203 vérifications sur 203 |
| 40 robots sur la version web (45 s chacun) | aucune erreur réelle (reste du bruit : champs libres qui acceptent n'importe quel texte) |
| Test final sur le TECNO (API réelle, MySQL, Cloudinary installé) | voir ci-dessous |

### Défauts trouvés pendant cette vérification, corrigés

| Gravité | Défaut | Correction |
|---|---|---|
| **Grave** | **B4 « Paiement réussi » s'affichait vide** (« Aucun paiement à afficher ») après un vrai paiement. La route de succès ne transportait pas l'identifiant, B3 est détruit à la navigation et GetX recrée un contrôleur vide. Les tests du lot ne le voyaient pas, car ils remplaçaient B4 par un `SizedBox`. | `PaymentController.pay` passe `parameters: {'id': ...}` ; nouveau test du parcours réel `test/payment/payment_flow_test.dart` (échoue sans la correction). |
| **Grave** | Après un paiement, **Mon loyer gardait les anciens chiffres** (73 % au lieu de 80 %). | Mon loyer se relit au retour de l'écran de paiement ; « Retour à mon loyer » revient à la page existante. |
| **Grave** | **Un utilisateur connecté qui ouvrait « Réinitialiser mon mot de passe » (nouveau lien du Profil) était déconnecté** : `AuthController` ferme la session à sa création. | Contrôleur dédié `ForgotPasswordController` (5 tests, dont la régression). |
| Gênant | Un double appui sur « Retour » dépilait deux pages, voire quittait la dernière (exception ; même cause que celle d'onboarding signalée plus haut). La flèche était inerte après une déconnexion. | `AppBackButton` : un seul retour par appui, aucun s'il n'y a plus de page précédente (test avec vraie transition, échoue sans la correction). |

### Restent à faire (confirmés sur l'appareil ou dans le code)

| Gravité | Point | Où |
|---|---|---|
| **Grave** | « Appeler » et « WhatsApp » du détail d'annonce ne lancent rien : le numéro du propriétaire n'est pas dans la réponse de l'API (décision de confidentialité à prendre, voir `POINT-RESTE-A-FAIRE.md` §2.1). | `listing_details_page.dart`, `AnnouncementResource.php` |
| **Grave** | « Envoyer un rappel » (`POST /owner/rentals/{id}/remind`) et « mot de passe oublié » **répondent comme si un message était parti, mais rien n'est envoyé**. | `OwnerDashboardController`, `AuthController` |
| Gênant | C6 « Ajouter un locataire » : valeurs en dur (350 000, 700 000) et date de début toujours `01/03/2026`. | `property_form_page.dart` lignes 63 à 68 |
| Gênant | `manualPayment` invente le numéro `0100000000` quand le locataire n'en a pas. | `OwnerDashboardController` ligne 221 |
| Gênant | Le webhook accepte n'importe quelle requête quand le secret KKiaPay est vide (hors production : bloqué en production par un 503). | `PaymentController::webhook` |
| Mineur | Pas d'index unique `(announcement_id, reporter_id)` sur les signalements (doublon possible en cas de requêtes simultanées). | migration `reports` |
| Mineur | Le menu de développement et `PlaceholderPage` sont toujours dans le code. | `dev_menu_page.dart`, `placeholder_page.dart` |
| Information | Les tests `UploadTest` échouent sur les postes sans extension PHP GD (7 erreurs chez l'équipe, 0 ici). | environnement |

### Test final sur le TECNO

Vérifié à la main avec les requêtes reçues par le serveur : installation propre, connexion des trois rôles, paiement complet (formulaire, refus de saisie, succès, B4, reçu, retour), échec simulé, « Mot de passe oublié » depuis le Profil sans perte de session, détail d'annonce, signalement (envoi puis doublon refusé), propriétaire (logements Loué/Libre cohérents, encaissements), administrateur (signalements, vérifications, utilisateurs).
Non vérifié : appel téléphonique et WhatsApp (non branchés, voir plus haut), envoi de photo depuis la galerie, gardes de route par lien direct.
