# Guide de présentation — Faith

Ce document sert à expliquer, sans notes, ce qui concerne Faith : le lot 2, le lot 9 et le branchement entre l'application et le backend. Chaque partie dit quoi, où, comment et pourquoi, puis liste les questions probables.

## 1. En une minute

LofiSoft est une application Flutter (GetX) de location de logements au Bénin, avec un back Laravel. Trois rôles : locataire, propriétaire, administrateur.

Ce qui me concerne :
- **Lot 2** : le démarrage et l'entrée dans l'app. E0 Lancement, A5 Connexion, A6 Inscription, B1 Rejoindre mon logement.
- **Lot 9** : l'administration. D1 Signalements, D2 Vérifications d'identité. J'y ai ajouté une page Profil commune aux trois rôles.
- **Branchement backend** : le client HTTP, les services et repositories, les modes réel et simulé, la sécurité par rôle côté Laravel, les tests.

## 2. Comment l'app est construite

Chaque écran suit le même chemin, de haut en bas :

```
Page  ->  Contrôleur  ->  Repository  ->  Service  ->  ApiClient  ->  API Laravel
(UI)      (état, règles)   (données)      (1 appel)    (HTTP, jeton)
```

- **Page** : dessine l'écran, ne décide de rien. Les champs de texte (`TextEditingController`) vivent ici et pas dans le contrôleur.
- **Contrôleur GetX** : garde l'état (`Rx...`), appelle le repository, gère les erreurs et la navigation.
- **Repository** : transforme le JSON en objets (`models`), choisit entre réseau et cache.
- **Service** : un appel HTTP brut par méthode, sans logique. Il existe une version simulée (`Fake...Service`).
- **ApiClient** : unique, ajoute le jeton, applique le délai maximal, traduit les erreurs.

Dossiers : `core/` (thème, utilitaires), `data/` (cache, `remote/`, `repo/`), `domain/models/`, `presentation/` (`features/`, `components/`, `routes/`, `shared/`), et `di/` à la racine, qui enregistre `AuthStorage`, `AppStorage` et `ApiClient` au démarrage. Un **Binding** par écran fournit au contrôleur ce dont il a besoin.

Règles du projet : composants passifs, aucune couleur ou taille en dur (tout vient de `core/theme`), pas de donnée factice dans les vrais repositories, pas de navigation dans les services HTTP, identifiants dans le chemin de la route.

## 3. Le branchement backend

### 3.1 ApiClient (`data/remote/api_client.dart`)
- Construit l'adresse : `AppConfig.apiBaseUrl` + chemin. Par défaut `http://127.0.0.1:8000/api`.
- Ajoute `Authorization: Bearer <jeton>` si une session existe, et `Accept: application/json`.
- Délai maximal de 20 secondes.
- Traduit chaque réponse en succès ou en exception typée :

| Situation | Exception | Message affiché |
|---|---|---|
| Pas de réseau, délai dépassé | `NetworkException` | « Pas de connexion internet. » |
| 401 avec jeton | `UnauthorizedException` | session expirée, **la session locale est effacée** |
| 401 sans jeton (connexion ratée) | `UnauthorizedException` | message du serveur |
| 400 / 422 | `ValidationException` | première erreur de champ de Laravel |
| 5xx | `ServerException` | « Le serveur a rencontré un problème. » |
| autre (403, 404, 409) | `ServerException` | `message` du serveur |

- Une liste JSON brute (`[...]`) est enveloppée en `{"data": [...]}` pour que le reste du code lise toujours une map.
- Il ne navigue jamais : ce sont les contrôleurs qui réagissent.

### 3.2 Session (`data/cache/auth_storage.dart`)
Garde le jeton et le profil dans le stockage local (GetStorage). `hasSession` vaut vrai s'il y a un jeton et un rôle. Au démarrage, la session est revalidée par `GET /auth/me`.

### 3.3 Adresse du serveur et téléphone
- Téléphone en USB : `adb reverse tcp:8000 tcp:8000` puis `flutter run`. L'app parle alors à `127.0.0.1:8000`, que `adb` redirige vers le PC.
- Autre serveur : `--dart-define=API_BASE_URL=http://<adresse>:8000/api`.
- Mode sans serveur : `--dart-define=USE_FAKE_API=true`. Les Bindings choisissent alors `FakeXService` au lieu du vrai. Les repositories ne changent pas.
- « Pas de connexion internet » à la connexion signifie presque toujours : serveur arrêté, `adb reverse` perdu ou mauvaise adresse.

### 3.4 Côté Laravel
- Authentification par jeton **Sanctum**. Identifiants en UUID.
- Middleware `role:OWNER|TENANT|ADMIN` : un mauvais rôle reçoit **403**. Il passe avant la liaison des modèles, donc un non-admin n'apprend même pas si une ressource existe.
- Compte suspendu avec jeton valide : **401** « Ce compte a été suspendu. », ce qui déconnecte l'app proprement.
- Format d'erreur unique : `{ "message": "...", "errors": { "champ": ["..."] } }`, messages de validation en français (`lang/fr`).
- Téléphone : 10 chiffres commençant par `01`.
- Photos : `POST /api/uploads` envoie vers Cloudinary si `CLOUDINARY_URL` est renseigné, sinon vers le disque local.
- Paiement : mode simulé par défaut (`PAYMENT_DRIVER=fake`). Un paiement en attente devient réussi après quelques secondes, ou échoué si le numéro finit par `00`.

### 3.5 Principaux points d'accès utilisés

| Écran | Appel | Rôle |
|---|---|---|
| A5 | `POST /auth/login` | tous |
| A6 | `POST /auth/register` | tous |
| E0 / Profil | `GET /auth/me`, `POST /auth/logout` | connecté |
| B1 | `GET /housings/lookup?code=`, `POST /rentals/join` | locataire |
| D1 | `GET /admin/reports`, `POST /admin/reports/{id}/resolve`, `/dismiss` | admin |
| D2 | `GET /admin/identity-requests`, `POST .../approve`, `.../reject` | admin |
| E7 | `POST /uploads`, `POST /me/identity` | propriétaire |

## 4. Lot 2 — Entrée et connexion

### E0 Lancement (`features/splash/`)
- Joue l'animation (2,6 s minimum), puis décide où aller :
  1. Première ouverture de l'app → onboarding.
  2. Session en cache → revalidation par `/auth/me` (5 s maximum, sinon on garde le cache), puis l'accueil du rôle : locataire → Mon loyer, propriétaire → tableau de bord, admin → Signalements.
  3. Sinon → catalogue des annonces (visiteur).
- Le lancement ne reste jamais bloqué : un serveur éteint ne l'empêche pas d'ouvrir l'app.

### A5 Connexion (`features/auth/login_page.dart`, `auth_controller.dart`)
- Validation du formulaire (e-mail, mot de passe présent), puis `AuthController.login`.
- `AuthRepository.login` appelle le service, lit le jeton et l'utilisateur dans la réponse (plusieurs formes acceptées), enregistre la session.
- Redirection selon le rôle. Erreur : message sous le formulaire, bouton de nouveau actif.
- Un second appui pendant le chargement est ignoré.
- **Ouvrir la page de connexion ferme toute session restante** (jeton révoqué côté serveur, session locale effacée) : on repart toujours de zéro.

### A6 Inscription (`register_page.dart`)
- Champs : choix du rôle (locataire ou propriétaire), nom, prénoms, e-mail, téléphone, mot de passe, case des conditions. Le bouton reste inactif tant que la case n'est pas cochée.
- Le téléphone est nettoyé (espaces retirés) avant l'envoi. Le mot de passe doit être solide.
- Après succès : propriétaire → onboarding propriétaire, locataire → onboarding locataire.
- Erreurs du serveur (e-mail ou téléphone déjà pris) affichées telles quelles.
- Côté back, `RegisterRequest` tolère un seul des deux noms en le recopiant dans l'autre.

### B1 Rejoindre mon logement (`features/rental/`)
- Le locataire saisit le code du logement (7 caractères, ex. `M4T-83P`). Dès que le code est complet, l'app appelle `lookup` et montre un aperçu : titre, lieu, loyer, jour d'échéance, propriétaire, badge Vérifié.
- Il confirme (« Oui, c'est mon logement ») → `POST /rentals/join` crée une location **en attente**.
- Le propriétaire voit la demande sur son accueil et l'accepte ou la refuse. Une fois acceptée, la location est active.
- Règles du back : un locataire n'a qu'une location active ou en attente (409), un logement occupé refuse (409), un code inconnu donne 404.
- Accès depuis l'onglet « Mon loyer », via « Rejoindre mon logement ».

## 5. Lot 9 — Administration

### Navigation
Trois onglets : Signalements, Vérifications, Profil. Les routes : `/admin` et `/admin/reports` (D1), `/admin/verifications` (D2). Un seul contrôleur (`AdminController`) et un seul Binding pour les deux écrans.

### D1 Signalements
- Le back renvoie **une ligne par signalement**. L'app les **regroupe par annonce** (`ReportGroup`) pour montrer une carte par annonce, avec le motif le plus récent, le nombre de signalements et le propriétaire.
- **Voir** : ouvre l'annonce (écran A3).
- **Supprimer** : demande confirmation, puis résout *tous* les signalements de l'annonce avec l'action `REMOVE_ANNOUNCEMENT`. Le back passe l'annonce à `CANCELED`. Sans cela, la carte réapparaîtrait avec les signalements restants.
- **Ignorer** : classe tous les signalements de l'annonce comme `DISMISSED`.
- Si une requête échoue au milieu d'un groupe, seuls les signalements déjà traités disparaissent, la carte reste pour réessayer.
- Pendant une action, les boutons de la carte sont bloqués (pas de double envoi).

### D2 Vérifications d'identité
- Chaque demande montre le propriétaire, le nombre de logements, la pièce d'identité et le selfie.
- **Valider** : le back passe la demande à `APPROVED` et met `identity_verified` à vrai. Le badge « Vérifié » apparaît dans le fil d'annonces.
- **Refuser** : un motif est obligatoire (fenêtre de saisie). Le back enregistre le motif.
- Une demande déjà traitée donne 409 « Cette demande a déjà été traitée. ».

### Profil
Une page unique pour les trois rôles : initiales, nom, rôle, e-mail, téléphone, déconnexion avec confirmation. La déconnexion révoque le jeton côté serveur ; même sans réseau, la session locale est effacée.

### Ce que j'ai ajouté au back pour le lot 9
`GET /admin/reports` renvoie maintenant la ville et le nom du propriétaire de l'annonce, et `GET /admin/identity-requests` le nombre de logements du propriétaire. Ces champs manquaient aux maquettes. Ajout sans effet sur les anciens clients.

## 6. Tests

- Mobile : environ 330 tests (`flutter test`), 6 ignorés (les « goldens » d'images, qui échouent sous Linux pour des raisons de rendu, pas à cause du code).
- Back : 248 tests (`php artisan test`), sur SQLite en mémoire, sans réseau.
- Ils couvrent : modèles, repositories sur un faux serveur HTTP, contrôleurs, pages principales, faux services, bindings, et côté back les rôles, les cas d'erreur et la cohérence des données de démonstration.
- Documentation des tests : `backend/docs/03-tests.md`.

## 7. Démonstration conseillée (5 minutes)

Mode réel (back lancé, `adb reverse` fait). Comptes de démonstration, mot de passe `Test1234` : `admin@lofi.bj`, `proprio@lofi.bj`, `locataire@lofi.bj`.

1. Lancer l'app : le splash puis le catalogue (visiteur).
2. Se connecter en **propriétaire** : tableau de bord, « Logements » → « + Ajouter » pour créer un logement, noter son **code**.
3. Se déconnecter (Profil). S'inscrire ou se connecter en **locataire**, onglet « Mon loyer » → « Rejoindre mon logement », saisir le code, confirmer : « Demande envoyée ».
4. Revenir en **propriétaire** : section « Demandes de location », **Accepter**.
5. Se connecter en **admin** : D1 (supprimer ou ignorer un signalement), D2 (valider une identité), Profil → se déconnecter.

## 8. Limites à connaître (à dire franchement)

- **Paiement locataire (B3 Payer, B4 Paiement réussi)** : écrans non faits. Le back et le paiement simulé existent, le bouton « Payer mon loyer » n'a pas encore de destination.
- **A2 Filtres** : pas de page dédiée, seuls les critères de l'onboarding filtrent le fil.
- **Mot de passe oublié** : page provisoire.
- **Expiration de session** : pas de redirection automatique vers la connexion depuis n'importe quel écran, seulement un message sur l'écran en cours.
- **Protection des routes côté mobile** : les fichiers `auth_middleware.dart` et `role_middleware.dart` sont vides. La sécurité repose sur le **back** (jeton et rôles), qui refuse tout accès non autorisé. À dire clairement si on demande.
- **Gestion des utilisateurs par l'admin** (suspendre un compte) : existe côté back (`/admin/users`), pas d'écran mobile.
- **WhatsApp** : bouton « Bientôt ». « Appeler » ouvre le composeur du téléphone.
- **Création d'annonce** : adresse, point de repère et GPS de la maquette ne sont pas envoyés, le back n'a pas ces champs.
- **Adresse par défaut** du serveur : `127.0.0.1`, utilisable seulement avec `adb reverse` ou sur le même appareil.

## 9. Questions probables et réponses courtes

- **Pourquoi des services ET des repositories ?** Le service fait un appel, le repository décide quoi en faire (modèles, cache, enchaînements). On remplace le service par un faux sans toucher au reste.
- **Où est stocké le jeton ?** Dans `AuthStorage` (stockage local), ajouté automatiquement par `ApiClient` à chaque requête.
- **Que se passe-t-il si le jeton expire ?** Le back répond 401, `ApiClient` efface la session locale et l'écran concerné affiche « Session expirée. Reconnectez-vous. ». Au prochain lancement, le splash n'a plus de session et mène au catalogue visiteur. Il n'y a pas de redirection automatique vers la connexion depuis n'importe quel écran (voir les limites).
- **Pourquoi regrouper les signalements dans l'app ?** Le back stocke un signalement par ligne, la maquette montre une carte par annonce.
- **Comment éviter qu'un locataire accède à `/admin` ?** Le middleware `role:ADMIN` du back renvoie 403, quoi que fasse l'app.
- **Comment travailler sans serveur ?** `--dart-define=USE_FAKE_API=true`.
- **Pourquoi `adb reverse` ?** Le téléphone n'est pas sur le même réseau que `localhost` du PC. Cette commande fait passer le port 8000 du téléphone par le câble USB vers celui du PC.

## 10. Commandes

```
# back
cd backend && php artisan serve --host=0.0.0.0 --port=8000
php artisan migrate:fresh --seed        # remet la base à zéro (efface tout)
php artisan test

# mobile
cd mobile
adb devices && adb reverse tcp:8000 tcp:8000
flutter run                              # vrai back
flutter run --dart-define=USE_FAKE_API=true   # sans serveur
flutter test && flutter analyze

# vider les données de l'app sur le téléphone
adb shell pm clear com.lofisoft.mobile
```
