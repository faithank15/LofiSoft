# LofiSoft — Rapport d'Ingénierie Backend Laravel
**Date :** Octobre 2026  
**Auteur :** Raphaël  
**Statut :** Fondations complètes — Fonctionnalités métier en cours d'achèvement (Stade Alpha)

---

## 1. Synthèse de l'état actuel

### 1.1 Ce qui est implémenté et opérationnel
- **Schéma relationnel & Migrations PostgreSQL** :
  - Identifiants primaires et étrangers normalisés en `UUID`.
  - Migration Sanctum adaptée (`uuidMorphs('tokenable')`) pour éviter les conflits d'intégrité de types sous PostgreSQL/Supabase.
  - 10 tables alignées sur le contrat d'API : `users`, `housings`, `rentals`, `rent_periods`, `payments`, `announcements`, `announcement_photos`, `favorites`, `identity_requests`, `reports`.
- **Modélisation Eloquent (PHP 8.2+)** :
  - 9 modèles typés avec le trait `HasUuids` (`User`, `Housing`, `Rental`, `RentPeriod`, `Payment`, `Announcement`, `AnnouncementPhoto`, `IdentityRequest`, `Report`).
  - 9 énumérations strictes (`UserRole`, `RentalStatus`, `AnnouncementStatus`, `AccommodationType`, `ReportStatus`, `RentStatus`, `PaymentStatus`, `Operator`, `IdentityStatus`).
  - Casts stricts sur les montants monétaires en entiers (`integer`, FCFA sans décimales).
- **Routage et Contrôleurs** :
  - 32 endpoints contractuels (50 routes avec équivalents `HEAD`) déclarés et mappés dans `routes/api.php`.
  - Architecture modulaire dans `app/Http/Controllers/Api/` isolant les contextes (Auth, Housing, Announcement, Rental, Payment, Owner, Admin, Upload).
  - Génération unique du code logement court (format `XXX-XXX`) intégrée au modèle `Housing`.

---

## 2. Matrice des écarts (Contrat d'API vs Implémentation réelle)

| Domaine | Spécifié dans le contrat / CDC | État dans le code actuel | Niveau de criticité |
|---|---|---|---|
| **Contrôle d'accès (RBAC)** | Accès strict par rôle (`TENANT`, `OWNER`, `ADMIN`) | Seul `auth:sanctum` est actif ; rôles vérifiés manuellement | **Bloquant (Sécurité)** |
| **Persistance des médias** | Cloudinary obligatoire (disque éphémère Render) | Stockage local `storage/app/public` | **Bloquant (Production)** |
| **Passerelle de paiement** | Mobile Money MTN / Moov via KKiaPay | Statut `PENDING` statique sans appel API externe | **Bloquant (Fonctionnel)** |
| **Webhook de paiement** | Validation de la transaction et mise à jour du statut | Endpoint recevant des données brutes sans vérification de signature | **Bloquant (Sécurité/Fraude)** |
| **Calcul des loyers** | Report automatique des impayés et des surplus d'un mois sur l'autre | Calcul ponctuel à la volée sur le mois en cours uniquement | **Majeur (Comptabilité)** |
| **Gestion des erreurs** | Format JSON uniforme `{message, errors}` pour tout code HTTP | Seules les FormRequests retournent ce format ; 404/500 utilisent le format Laravel natif | **Majeur (Intégration Flutter)** |
| **Notifications** | Push FCM avant/après échéance + e-mails | Aucun driver, modèle de token FCM ni notification programmée | **Mineur (Phase 2)** |

---

## 3. Détail des chantiers restants pour finalisation totale

### Chantier 1 : Sécurisation et Middlewares de rôles
- **Problème** : Un locataire authentifié peut actuellement envoyer une requête `POST /api/housings` ou appeler les routes `/api/owner/*` si une vérification ponctuelle est omise dans le contrôleur.
- **Action requise** :
  - Créer un middleware `EnsureUserHasRole` acceptant un ou plusieurs rôles en paramètres.
  - Enregistrer l'alias dans `bootstrap/app.php`.
  - Protéger les groupes de routes dans `routes/api.php` :
    - `middleware(['auth:sanctum', 'role:OWNER'])` pour `/api/owner/*` et l'écriture des logements/annonces.
    - `middleware(['auth:sanctum', 'role:TENANT'])` pour les paiements et le rattachement de location.
    - `middleware(['auth:sanctum', 'role:ADMIN'])` pour `/api/admin/*`.

### Chantier 2 : Service d'Upload Cloudinary
- **Problème** : L'hébergement Render détruit le système de fichiers local toutes les 15 minutes d'inactivité ou lors des déploiements.
- **Action requise** :
  - Installer le SDK Cloudinary (`cloudinary-labs/cloudinary-laravel` ou service cURL léger sans dépendance lourde).
  - Configurer `CLOUDINARY_URL` dans le fichier `.env`.
  - Mettre à jour `UploadController` pour téléverser directement vers les dossiers Cloudinary appropriés (`announcements/`, `identities/`) et renvoyer l'URL publique HTTPS sécurisée.

### Chantier 3 : Intégration KKiaPay & Webhook sécurisé
- **Problème** : Le locataire ne peut pas réellement déclencher le débit USSD Mobile Money (MTN / Moov).
- **Action requise** :
  - Créer un service `KkiapayService` encapsulant les appels API pour initialiser la transaction.
  - Implémenter la vérification cryptographique de l'en-tête de signature du webhook KKiaPay pour empêcher toute falsification de paiement.
  - En cas de paiement `SUCCESS`, déclencher la mise à jour transactionnelle du solde de la période de loyer (`RentPeriod`).

### Chantier 4 : Moteur d'échéances et Commandes Artisan (Cron)
- **Problème** : Le passage d'un mois à l'autre ne reporte pas automatiquement les dettes précédentes (`carried_over`), rendant impossible la détection des retards (`LATE`) pour les locataires qui ne consultent pas l'application.
- **Action requise** :
  - Créer une commande console Artisan `rent:generate-monthly-periods` exécutée chaque 1er du mois à 00h00.
  - Pour chaque location active :
    - Calculer le reliquat du mois précédent (total dû - somme des paiements réussis).
    - Créer la nouvelle ligne `RentPeriod` avec `carried_over = reliquat`.
    - Mettre à jour le statut global du bail si nécessaire.

### Chantier 5 : Gestionnaire global d'exceptions (bootstrap/app.php)
- **Problème** : Si une ressource n'est pas trouvée (ex. `/api/announcements/invalid-uuid`), Laravel renvoie une réponse standard qui ne respecte pas le contrat `{ "message": "Ressource introuvable." }`.
- **Action requise** :
  - Configurer `withExceptions()` dans `bootstrap/app.php` pour intercepter `NotFoundHttpException`, `AccessDeniedHttpException` et `AuthenticationException` afin de renvoyer strictement la charge JSON attendue par l'application mobile en français.

### Chantier 6 : Jeux de données et Tests d'intégration
- **Action requise** :
  - Écrire les seeders de démonstration complets (`DatabaseSeeder`) initialisant les comptes du fichier `FakeAuthService.dart` du mobile (`locataire@lofi.bj`, `proprio@lofi.bj`, `admin@lofi.bj`).
  - Écrire une suite de tests automatisés (Pest ou PHPUnit) couvrant au minimum le cycle critique : Inscription → Création logement → Récupération code → Rattachement locataire → Paiement partiel → Consultation solde.

---

## 4. Feuille de route d'implémentation ordonnée

```
Étape 1 : Sécurité & Exceptions (bootstrap/app.php + Middleware de Rôle)
    │
Étape 2 : Service Cloudinary & UploadController réel
    │
Étape 3 : Moteur de calcul des loyers & Commande console de rollover
    │
Étape 4 : Passerelle de paiement KKiaPay & Sécurisation Webhook
    │
Étape 5 : Seeders de test & Validation de bout en bout avec Flutter
```