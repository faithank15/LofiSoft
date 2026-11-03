# Point — ce qu'il reste à faire

Date : 3 novembre 2026. Base : `origin/darko/dev` (`d730b1a`), à jour avec `origin/main`.

> **Mise à jour du 3 novembre 2026 — fin de session.** Les priorités 1 et 3
> (§2.5 `paid`, §2.6 `forgotPassword`, `remind`, `manualPayment`) sont
> **terminées et testées**. La **régénération de mot de passe** est livrée
> (mail réel + page web de réinitialisation). Le reste (§2.1 Appeler/WhatsApp,
> §2.2 itinéraire, §2.8, §2.9) est confié à un autre collaborateur : c'est
> décrit ci-dessous sans ambiguïté. Détail des travaux dans **§7**.

Ce fichier est un **état des lieux réel, vérifié dans le code**, pas une reprise du
constats de test. Plusieurs points du fichier `CONSTATS-PAR-LOT.md` (daté du
3 novembre) sont **déjà corrigés** depuis : c'est signalé ici pour éviter de
refaire du travail.

État vérifié au moment de la rédaction :

| Vérification | Résultat |
|---|---|
| `cd mobile && flutter test` | 378 passent, 6 ignorés |
| `cd backend && php artisan test` | 260 tests, 929 assertions, **7 erreurs** (`UploadTest` uniquement, §2.9), 6 dépréciations PHPUnit |
| `flutter analyze` | 34 remarques, aucune nouvelle |
| Routes API | **53** routes réelles (`php artisan route:list`), 58 au total. Toutes résolvent vers une classe **et** une méthode existantes : **aucun contrat cassé**. |
| Agents d'exploration | Inventaire mobile et backend rendus, croisés |

---

## 1. Ce qui est déjà fait (ne pas le refaire)

| Point du constats | État réel |
|---|---|
| `report_service.dart` et `report_repository.dart` « vides » | **Fait.** Les deux implémentent l'appel `POST /announcements/{id}/reports`. |
| « Aucun écran pour signaler une annonce » | **Fait.** Bouton « Signaler cette annonce » dans `listing_details_page.dart` (lignes 421, 428), dialogue `_showReportDialog` (ligne 56), branché sur le vrai backend. |
| Écran D1 « Signalements » sans données | **Fait.** Chaîne complète : `admin_service.dart` → `GET /admin/reports` → `admin_controller.dart` → groupes. Le backend gère le doublon (409 « Vous avez déjà signalé cette annonce »), la résolution et le rejet. |
| B3 / B4 « n'existent pas » | **Fait** (lots 6, déjà poussés). |
| Itinéraire absent | **Partiellement fait.** Le bouton existe et ouvre Google Maps (voir §2.2). |
| WhatsApp de « Mon loyer » (B2) | **Fait.** `rent_tracking_page.dart` ligne 27 : vraie ouverture `https://wa.me/…` avec message pré-rempli. |
| Appeler le propriétaire depuis « Mon loyer » | **Fait.** `rent_tracking_page.dart` ligne 65 : vrai `tel:`. |
| Cloudinary absent de `vendor/` | **Fait sur ce poste.** `vendor/cloudinary/cloudinary_php` est présent. Reste à faire sur les autres postes. |
| Bruit de l'analyseur (imports inutilisés, `Share` déprécié) | **Fait.** Nettoyé au passage (34 remarques restantes, sans rapport). |
| **Récupération de mot de passe** | **Fait et testé** (voir §7). Mail réel envoyé, page web `/reset-password`, jetons de session révoqués. |
| **Rappel de loyer au locataire** (`remind`) | **Fait et testé.** Mail réel via `RentReminderNotification`. |
| **Paiement en espèces sans numéro inventé** (`manualPayment`) | **Fait et testé.** 422 si le locataire n'a pas de téléphone. |
| **`TenantRent.paid`** | **Fait et testé.** Exporté par le backend. |

---

## 2. Ce qu'il reste réellement à faire

### 2.1 « Appeler » et « WhatsApp » sur le détail d'annonce (A3) — **Grave**

Les deux boutons existent mais ne font rien :

| Bouton | Emplacement | Comportement actuel |
|---|---|---|
| Appeler | `listing_details_page.dart` ligne 503-509 | Snackbars « Entrez en contact avec … après visite » |
| WhatsApp | `listing_details_page.dart` ligne 531-537 | Snackbars « Le canal WhatsApp propriétaire est en cours de déploiement » |

**Cause racine : le numéro du propriétaire n'est disponible nulle part.**

- Backend, `app/Http/Resources/AnnouncementResource.php` lignes 35-41 : sur
  `announcements.show`, le champ `owner` ne contient que `id` et `name`.
  **Pas de téléphone.**
- Mobile, `lib/domain/models/announcement_model.dart` : `AnnouncementModel` n'a
  aucun champ téléphone (ni coordonnées).

**Faits de format et de sécurité, vérifiés :**

- La colonne s'appelle **`telephone`** (pas `phone`) sur `users`
  (`0001_01_01_000000_create_users_table.php:16`, `User.php:24`). La colonne
  `phone` existe, mais uniquement sur `payments` : c'est le numéro de
  l'opérateur MTN/Moov débité, pas celui d'une personne.
- **Format stocké : 10 chiffres, sans préfixe** (`0197000001`), garanti par la
  regex `^01[0-9]{8}$` de `RegisterRequest.php:74`. Jamais `+229`.
- **Aucune politique de masquage n'existe** dans le backend : `$hidden` du
  modèle `User` (lignes 32-35) ne couvre que `password` et `remember_token`.
  Pas de middleware, pas de Policy. Conséquence : le téléphone est déjà exposé
  par le haut dans plusieurs endpoints (voir la note en fin de section).
- **Aucun endpoint de demande de contact** n'existe : ni route, ni table
  (`messages`, `contacts`, `appointments`), ni contrôleur. Le canal
  « je souhaite visiter ce logement » est entièrement absent des deux côtés.

**Travail à faire**

1. Backend — `AnnouncementResource` : ajouter `owner.telephone` (le modèle
   `User` porte la colonne `telephone`) dans la branche `announcements.show`.
2. Backend — test : vérifier que le téléphone apparaît sur le détail et
   **qu'il n'apparaît pas** dans la liste (`announcements.index`), pour ne pas
   exposer le numéro de tout propriétaire à tout visiteur du fil.
3. Mobile — `AnnouncementModel` : ajouter `ownerPhone`, le lire dans
   `fromJson` (`owner.telephone`) et le propager dans `copyWith`.
4. Mobile — factoriser les handlers : `_call` et `_openWhatsApp` existent déjà
   dans `rent_tracking_page.dart` (lignes 27 et 65) mais sont dupliqués en
   private dans la page. Les sortir dans un service partagé, par exemple
   `lib/data/remote/services/contact_service.dart` ou
   `lib/presentation/shared/contact_actions.dart`, et les réutiliser aux deux
   endroits.
5. Mobile — brancher les deux boutons, avec les messages d'erreur déjà
   éprouvés (« Le numéro du propriétaire n'est pas connu », « Impossible
   d'ouvrir l'application WhatsApp »).
6. Mobile — tests : bouton actif quand le numéro existe, message clair quand il
   manque, format du numéro (`229…` sans `+`, comme dans `wa.me`).

**Point d'attention produit.** Exposer le téléphone de tous les propriétaires
sur le détail d'annonce est un choix de conception à valider : c'est le numéro
de téléphone de la personne, et l'annonce est visible par tous. Deux options :
(a) l'exposer tel quel, comme le fait déjà l'écran « Mon loyer » pour le
bailleur ; (b) ne l'exposer qu'après une demande de contact validée par le
propriétaire. La maquette A3 suppose un accès direct, l'option (a) est donc
cohérente avec le maquettage.

**À savoir : le téléphone est déjà exposé ailleurs, sans contrôle.**
`GET /api/me/rental` sérialise le modèle `User` complet (donc `telephone`,
`email`, `role` du propriétaire) ; `GET /api/housings` et `/housings/{id}`
font de même pour le **locataire** ; `GET /api/owner/requests` renvoie
`tenant_phone` ; `GET /api/admin/users` renvoie tous les téléphones.
Il n'y a donc pas de secret à protéger sur ce champ — mais l'exposition
directe du propriétaire sur une annonce **publique et non authentifiée**
est un choix distinct, à trancher explicitement.

**Test à étendre.** `backend/tests/Feature/AnnouncementTest.php:113-123`,
méthode `test_show_returns_description_and_owner` : c'est là qu'il faut
ajouter l'assertion sur `owner.telephone`, et une assertion vérifiant que le
téléphone **n'apparaît pas** dans le fil (`announcements.index`, route publique
sans authentification).

### 2.2 Itinéraire : de la recherche texte à un vrai trajet — **Gênant**

`listing_details_page.dart` ligne 41 `_openMaps(query)` ouvre :

```
https://www.google.com/maps/search/?api=1&query=<quartier, ville>
```

C'est une **recherche**, pas un itinéraire : pas d'origine, pas de destination
précise, et la carte s'ouvre sur le quartier entier.

**Cause racine : aucune coordonnée GPS n'existe dans le projet.**

- Backend : pas une seule colonne `latitude` / `longitude` dans les 13
  migrations (`housings`, `announcements`, `properties`…).
- Mobile : `AnnouncementModel` n'a que `city` et `district`.

**Deux voies possibles**, à valider avant de commencer :

- **(A) Géocodage à la volée — recommandé pour démarrer.** **Attention :
  `GeolocationService` ne sait faire que le géocodage *inverse*** (coordonnées →
  ville/quartier). Ses seules méthodes publiques sont `currentPosition()`
  (`geolocation_service.dart:28`) et `reverseGeocode(GeoPoint)` (ligne 60) ;
  l'appel Nominatim (ligne 69) et l'appel Google (ligne 113) sont privés et
  orientés « position → adresse ». Il n'existe **aucun géocodage direct**
  (texte → coordonnées) : il faut donc écrire cette méthode
  (`geocode(String adresse)`), sur le modèle de `_nominatim` mais en
  appelant `/search` au lieu de `/reverse`. Une fois la position du logement
  obtenue, on ouvre `maps/dir` avec l'origine = position GPS de l'utilisateur
  et la destination = le logement. **Aucune migration backend**, la
  fonctionnalité est livrable immédiatement.
- **(B) Coordonnées en base.** Migration `housings.latitude/longitude`,
  saisie par le propriétaire à la création du logement (formulaire C3), exposition
  dans l'API. Plus exact et plus rapide, mais touche le schéma, les formulaires
  et les tests.

(A) puis (B) est l'ordre naturel : on livre l'itinéraire tout de suite, puis on
affine avec la position réelle choisie par le propriétaire.

### 2.3 Actions « Bientôt » du tableau de bord propriétaire (C1) — **Mineur**

`lib/presentation/features/owner_dashboard/owner_dashboard_view.dart` ligne 47 :
le helper `showSoon(message)` affiche une snackbar « Bientôt ». À la date de
la rédaction, **aucun appelant n'a été trouvé** dans `lib/` : le helper est
mort, il reste donc soit à brancher sur les actions concernées, soit à
supprimer. À vérifier sur l'appareil : certaines actions de l'accueil C1
peuvent encore afficher « Bientôt » via un autre chemin.

### 2.4 Code mort et code de développement à retirer — **Mineur**

Repéré par un inventaire exhaustif des chaînes « stub » dans `lib/` :

| Élément | Emplacement | Nature |
|---|---|---|
| `PlaceholderPage` | `lib/presentation/shared/placeholder_page.dart` | **Code mort** : aucune route ne l'utilise (grep → seule sa propre définition). Contient le libellé « Écran à venir ». |
| `DevMenuPage` | `lib/presentation/features/dev/dev_menu_page.dart` lignes 15-17 | Menu **temporaire de développement**, à supprimer avant livraison. La route `AppRoutes.dev` est bien active dans `app_pages.dart` ligne 71. |
| `showSoon()` | `owner_dashboard_view.dart` lignes 46-49 | Code mort (voir §2.3). |
| `FakeAnnouncementService` | `lib/data/remote/fakes/fake_announcement_service.dart` | Les 5 annonces en dur n'ont pas de `owner.telephone` ni de coordonnées : à mettre à jour en même temps que le modèle (§2.1). |

### 2.5 Champs que le backend ne renvoie pas encore — **Mineur**

| Champ | Fichier | Conséquence |
|---|---|---|
| `TenantRent.paid` | `owner_dashboard_model.dart` lignes 87, 102, 141 | ✅ **Corrigé.** `'paid' => $paid` ajouté dans `OwnerDashboardController::tenants`. Test `OwnerTest::test_tenants_list_exposes_the_paid_amount` : `due=100000`, `paid=40000`, `status=PARTIAL`. **Il reste à vérifier côté mobile** que `owner_dashboard_model.dart` consomme bien ce champ et que `fake_owner_dashboard_service.dart` soit aligné (non vérifié). |

> **Correction par rapport à ma première version de ce fichier :**
> `HousingPreview.dueDay` et `HousingPreview.ownerVerified` **sont déjà
> alimentés** — `HousingController.php:87-88` renvoie bien `due_day` et
> `owner_verified` dans `/api/housings/lookup`. Le commentaire de
> `rental_model.dart` ligne 4 est périmé, pas l'API. Rien à faire.

### 2.6 Stubs backend : des boutons qui font semblant — **Grave**

C'est le cœur du « connecter tout ce qui est vide côté backend ». Ces actions
répondent à l'utilisateur **comme si elles avaient fonctionné**, sans aucun
effet réel.

| Endpoint | Fichier:ligne | Ce qu'il se passe |
|---|---|---|
| `POST /api/auth/forgot-password` | `AuthController.php:81-96` | ✅ **Corrigé.** `Password::sendResetLink` est appelé, la réponse reste identique que l'adresse existe ou non (pas de fuite d'information), et le mail part vraiment (§7). |
| `POST /api/owner/rentals/{rental}/remind` | `OwnerDashboardController.php:187-214` | ✅ **Corrigé.** `RentReminderNotification` part réellement au locataire ; 422 si le locataire n'a pas d'e-mail. |
| `POST /api/payments` | `PaymentController.php:46-54` | Le paiement est créé `PENDING` avec une **référence locale fabrique** (`RC-` + date + 4 caractères aléatoires, ligne 53). **Aucun appel KKiaPay** : le grep ne trouve que la vérification du secret du webhook et la config. En driver `kkiapay`, un paiement reste donc `PENDING` jusqu'au webhook — et en driver `fake`, le règlement est simulé localement. **Le backend ne peut pas encaisser un vrai MTN/Moov.** |
| `POST /api/payments/webhook` | `PaymentController.php:132-141` | Si le secret KKiaPay est vide et qu'on n'est pas en production → **aucune vérification de signature**. N'importe qui peut faire passer un paiement `PENDING` en `SUCCESS`. |
| `POST /api/owner/payments/manual` | `OwnerDashboardController.php:216-264` | ✅ **Corrigé.** Le numéro inventé `0100000000` est supprimé : le paiement porte le **vrai** téléphone du locataire, et l'API répond 422 s'il n'y en a pas. |
| `POST /api/auth/me/identity` → validation | `AppServiceProvider.php` | `register()`/`boot()` sont **vides** : aucun binding de gateway, pas de `app/Contracts/`, pas de `app/Policies/`, alors que `docs/01-architecture.md` §2 l'exige. Le choix Cloudinary / disque local se fait par `config()` dans `ImageStorage.php:23-26`, pas par contrat. |

**Absence structurelle : aucune infrastructure de notification.** Zéro route,
zéro table, zéro contrôleur pour le WhatsApp, le SMS, le push ou le mail —
`grep -rniE "whatsapp|twilio|sms|fcm|firebase|push|onesignal|apns"` sur
`app/ database/ routes/ config/` ne renvoie **rien**. Le seul `Notifiable` est
le trait Laravel sur `User`, inutilisé. Pas de `app/Notifications/`,
pas d'`app/Events/`, pas d'`app/Listeners/`.

> Conséquence directe : le bouton « Envoyer un rappel » du tableau de bord
> propriétaire (C1) et le « mot de passe oublié » sont **des mensonges
> silencieux**. C'est plus grave que les boutons absents : l'utilisateur a
> une confirmation qui n'est pas fondée.

**Aucun endpoint de contact du propriétaire** non plus : ni route, ni table
(`messages`, `contacts`, `appointments`), ni contrôleur. Le canal
« je souhaite visiter ce logement » est entièrement absent des deux côtés.

### 2.7 Endpoints backendorphelins : câblés côté serveur, jamais appelés par le mobile — **Mineur**

Le backend propose des routes que l'application n'exploite pas. Ce sont des
fonctionnalités prêtes à l'emploi, à brancher :

| Route | Contrôleur | Où elle servirait |
|---|---|---|
| `PUT /api/me` | `AuthController@updateProfile` | Modifier son profil (le profil mobile n'est que consultation). |
| `PUT /api/me/password` | `AuthController@updatePassword` | Changer son mot de passe — **absent de l'app**. |
| `GET /api/me/rent/periods` | `RentalController@rentPeriods` | Historique des loyers (mensuels/annuels). |
| `GET /api/me/announcements` | `AnnouncementController@myAnnouncements` | Mes annonces côté propriétaire (le mobile passe par une autre route). |
| `PUT /api/announcements/{id}` | `AnnouncementController@update` | Modifier une annonce. |
| `POST /api/announcements/{id}/cancel` | `AnnouncementController@cancel` | Annuler une annonce. |
| `GET /api/owner/tenants/{rentalId}` | `OwnerDashboardController@tenantDetails` | Fiche détaillée d'un locataire (avec ses paiements). |
| `POST /api/owner/payments/manual` | `OwnerDashboardController@manualPayment` | Enregistrer un paiement en espèces — **c'est la version manuelle du paiement, déjà écrite côté backend**. |
| `GET /api/me/rental` | `RentalController@currentRental` | Redondant avec `/me/situation`, déjà utilisé. |

À l'inverse, `POST /api/auth/forgot-password` est l'inverse : appelé par le
mobile mais **mort des deux côtés** (§2.6).

### 2.8 Deux détails de robustesse — **Mineur**

- **Unicité des signalements non garantie en base.** `AnnouncementController.php:207`
  vérifie en applicatif qu'un utilisateur n'a pas déjà signalé l'annonce (→ 409),
  mais la migration `create_reports_table.php` n'a **aucun index unique** sur
  `(announcement_id, reporter_id)`. Deux requêtes simultanées passent toutes
  les deux le contrôle → doublon possible. Correctif : un
  `$table->unique(['announcement_id', 'reporter_id'])`.
- **`CloudinaryService::delete()` n'est appelé nulle part.** La suppression
  d'annonce ne supprime pas les images côté Cloudinary — elles restent orphelines
  et facturées.

### 2.9 Tests backend `UploadTest` — **Mineur (environnement)**

Les 7 tests qui échouent le font tous avec `LogicException: GD extension is not
installed`. Ce n'est **pas un bug de code** : la fabrication des images de test
(`UploadedFile::fake()->image(...)`) exige l'extension GD de PHP, absente de
ce poste. Deux actions possibles : installer GD (`extension=gd` dans le `php.ini`
— sur Windows, activer `php_gd.dll` dans `php.ini` puis redémarrer Apache/PHP),
ou faire ignorer ces tests sur les postes sans GD.

---

## 3. Vérifications à faire à la main sur l'appareil

Le fichier `CONSTATS-PAR-LOT.md` le rappelle : les robots ne remplacent pas un
test à la main sur téléphone. Restent à vérifier sur le TECNO :

- D1, D2 et Profil (constat déjà signalé, lot 9).
- Le double-clic sur « Retour » pendant l'onboarding ville (constat, lots 3-4).
- Les nouveaux boutons Appeler / WhatsApp / Itinéraire : sur un vrai appareil
  Android, `url_launcher` dépend des applications installées — WhatsApp doit
  être installé pour que `wa.me` s'ouvre, sinon l'application de navigateur
  prend le relais.

---

## 4. Ordre d'attaque recommandé

> **État au 3 novembre 2026 :** les priorités 1 et 3 (points 1, 2, 3, 6) sont
> **terminées et testées** — voir §6. Les priorités 2 et le reste de la 3 sont
> confiés à un autre collaborateur — le détail est en §6.3.

**Priorité 1 — ce que l'utilisateur croit déjà fait et qui ne l'est pas**
(bogues de confiance : une confirmation affichée qui n'est pas fondée)

1. ✅ **2.6 `forgotPassword`** — **fait** : `Password::sendResetLink` + mail
   réel + page web `/reset-password` (§6.1).
2. ✅ **2.6 `remind`** — **fait** : mail réel au locataire (§6.2).
3. ✅ **2.6 `manualPayment`** — **fait** : le numéro inventé `0100000000` a
   disparu, 422 si le locataire n'a pas de téléphone (§6.2).

**Priorité 2 — les fonctionnalités demandées, visibles sur le téléphone**

4. **2.1 Appeler / WhatsApp sur A3** — le plus visible, le plus court, données
   déjà disponibles côté base (le téléphone est en base, il falta juste l'exposer).
5. **2.2 Itinéraire, voie (A)** — écrire le géocodage direct dans
   `GeolocationService`, pas de migration backend.

**Priorité 3 —-Fiabilisation et finitions**

6. ✅ **2.5** exporter `paid` dans `OwnerDashboardController` — **fait**.
7. **2.8** index unique sur les signalements + suppression des images
   Cloudinary à la suppression d'annonce.
8. **2.3 + 2.4** nettoyage : helper `showSoon` mort, `PlaceholderPage`,
   `DevMenuPage`.
9. **2.9** installation de GD sur le poste de dev (à faire une fois pour tout
   le monde) + migration des 6 `@dataProvider` en attributs `#[DataProvider]`.

**Priorité 4 — à planifier, car chacun est un chantier**

10. **2.2 voie (B)** — coordonnées en base, quand le formulaire propriétaire
    pourra les saisir.
11. **Passerelle de paiement KKiaPay réelle** (§2.6) — sans elle, le paiement
    MTN/Moov ne peut pas être encaissé. C'est le chantier le plus lourd.
12. **Infrastructure de notification** (push/WhatsApp/email) — prérequis de
    toute la messagerie et des rappels. *(Le canal mail existe désormais pour
    le mot de passe oublié et le rappel de loyer : voir §6.1 et §6.2.)*
13. **2.7 brancher les endpoints orphelins** — mot de passe, historique des
    loyers, modification/annulation d'annonce, fiche locataire, paiement
    manuel.
14. **Endpoint de demande de contact** (visite, RDV) — à créer de zéro : table,
    contrôleur, écran.

## 5. Ce qui n'a pas besoin d'être fait

Pour éviter de refaire du travail, ces points ont été vérifiés et sont **soit
corrigés, soit sans objet** :

- **Les signalements** (`report_service.dart`, `report_repository.dart`, bouton
  « Signaler cette annonce », `AnnouncementController@report`,
  `AdminController@reports/resolveReport/dismissReport`) : **chaîne complète
  et fonctionnelle**.
- **Le paiement en espèces par le propriétaire** (`manualPayment`) : déjà
  écrit côté backend, il reste juste à l'exposer dans l'app.
- **Les routes API** : 53 routes, toutes résolues, aucun contrôleur
  inexistant, aucune action vide.
- **`HousingPreview.dueDay` et `ownerVerified`** : déjà alimentés (§2.5).
- **`ImageStorage` / `CloudinaryService` / `RentBalance`** : complets et
  fonctionnels.
- **Le test `UploadTest` qui échoue** : pas un bug de code, c'est GD (§2.9).

## 6. Ce qui a été livré le 3 novembre 2026 (session close)

### 6.1 Régénération de mot de passe — **livré et testé**

C'est le point sur lequel cette session s'arrête. Le flux complet est en place :

| Étape | Où |
|---|---|
| Demande du lien | `POST /api/auth/forgot-password` → `AuthController::forgotPassword` |
| Envoi du mail | `Password::sendResetLink` + `app/Notifications/ResetPasswordNotification.php` |
| Page de choix du mot de passe | `GET /reset-password` → `app/Http/Controllers/ResetPasswordController.php` + `resources/views/auth/reset-password.blade.php` |
| Enregistrement | `POST /reset-password` → `Password::reset`, puis révocation des jetons de session |

**Choix de conception : le lien du mail pointe vers une page web**, pas vers
une application mobile.

- Un lien `lofisoft://` aurait été mort pour toutes les versions déjà
  installées sur les téléphones, et aurait exigé un nouveau paquet Flutter.
- Un App Link (`https://…`) exige un domaine réel vérifié et une application
  web : `APP_URL` vaut `http://localhost` et il n'existe pas de front web.
- La page web sert donc de **repli** : elle marche partout, et pourra
  divent un jour la destination d'un App Link sans changer le mail.

**Détail de sécurité retenu :** la réponse HTTP est **identique** que
l'adresse existe ou non (« Si cette adresse existe, un lien de
réinitialisation a été envoyé. »), et le mail n'est envoyé que si le compte
existe. Un mot de passe réinitialisé **révoque les jetons d'API** existants
(les sessions ouvertes avec l'ancien mot de passe tombent).

**Tests ajoutés** (`backend/tests/Feature/Auth/AuthTest.php`) :
le mail part bien, le jeton stocké permet de réinitialiser, un jeton invalide
est refusé, la page s'affiche, la confirmation doit correspondre, le mail se
rend en HTML avec son lien, les sessions sont révoquées.

**Point d'environnement à signaler.** Le `.env` local avait `APP_LOCALE=en`
alors que `.env.example` déclare `fr` : les messages de validation de la page
sortaient **en anglais**. Le `.env` local a été aligné sur `fr` (le `.env` n'est
pas versionné ; c'est `.env.example` qui fait référence). Si un poste a le même
écart, les messages de la page seront en anglais.

### 6.2 Autres corrections livrées dans la même session

| Correction | Fichiers | Test |
|---|---|---|
| Rappel de loyer réellement envoyé au locataire | `OwnerDashboardController::remind`, `app/Notifications/RentReminderNotification.php` | `OwnerTest::test_remind_by_owner`, `test_remind_refuses_when_the_tenant_has_no_email` |
| Suppression du numéro de téléphone inventé | `OwnerDashboardController::manualPayment` | `OwnerTest::test_manual_payment_records_cash_success`, `test_manual_payment_refuses_when_the_tenant_has_no_phone` |
| Export de `paid` par le backend | `OwnerDashboardController::tenants` | `OwnerTest::test_tenants_list_exposes_the_paid_amount` |

**Point à faire de côté (non traité, hors périmètre de la session) :** le
`paid` exporté côté backend n'a été vérifié que par le test PHP. Il reste à
confirmer que `mobile/lib/domain/models/owner_dashboard_model.dart` lit bien ce
champ et que `mobile/lib/data/remote/fakes/fake_owner_dashboard_service.dart`
renvoie la même forme de données.

### 6.3 Ce qui reste — transmis au collaborateur

Par ordre d'intérêt :

1. **§2.1 — Appeler / WhatsApp sur le détail d'annonce (A3).** Le téléphone
   du propriétaire doit être exposé dans `AnnouncementResource` (branche
   `announcements.show` uniquement, **pas** dans le fil public), puis lu par
   `AnnouncementModel` et branché sur les deux boutons de
   `listing_details_page.dart`. Les handlers `_call` et `_openWhatsApp` de
   `rent_tracking_page.dart` (lignes 27 et 65) sont à factoriser dans un
   service partagé.
   **Décision déjà prise : option (a)** — le téléphone est exposé tel quel,
   en cohérence avec l'écran « Mon loyer » et le maquettage A3.
2. **§2.2 — Itinéraire.** Écrire `geocode(String adresse)` dans
   `GeolocationService` (appel Nominatim `/search` au lieu de `/reverse`),
   puis ouvrir `maps/dir/?api=1&destination=<lat,lng>` en omettant l'origine :
   Google Maps part alors de la position courante de l'utilisateur.
   Aucune migration backend n'est nécessaire pour la voie (A).
3. **§2.8 — Index unique sur les signalements** (`$table->unique(['announcement_id',
   'reporter_id'])`), en cohérence avec le 409 déjà présent dans
   `AnnouncementController`.
4. **§2.8 — Suppression Cloudinary à l'annulation d'une annonce.**
   `CloudinaryService::delete()` existe mais n'est appelé nulle part ; il
   faut l'appeler dans `AnnouncementController::cancel`, en respectant
   `belongsToApp()`.
5. **§2.3 + §2.4 — Code mort** : `showSoon()` (sans appelant),
   `lib/presentation/shared/placeholder_page.dart` (sans route),
   `lib/presentation/features/dev/dev_menu_page.dart` et la route
   `AppRoutes.dev`.
6. **§2.9 — Environnement de dev** : activer l'extension GD dans le `php.ini`
   (les 7 `UploadTest` échouent sans elle), et migrer les 6 `@dataProvider`
   en attributs `#[DataProvider]` (PHPUnit 11 déprécie la syntaxe docblock).

Restent hors périmètre, car ce sont des chantiers entiers : la passerelle de
paiement KKiaPay réelle, la signature du webhook, l'infrastructure de
notification (push/WhatsApp), l'endpoint de demande de contact, et le
branchement des endpoints orphelins (§2.7).

---

## 7. État Git au moment de la rédaction

- Branche `darko/dev` locale = `origin/darko/dev` = `d730b1a` au début de la
  session ; le travail de cette session (régénération de mot de passe et
  corrections P1) est commité et poussé sur `origin/darko/dev`.
- `origin/main` a été mis à jour (`8186e6b`) et contient déjà nos trois derniers
  commits (PR #6 mergée).
- Une modification locale non commitée : `mobile/lib/core/constants/app_config.dart`
  passe l'API de `10.140.106.79` à `127.0.0.1` (réglage de développement local,
  volontairement non commité). **Ne pas l'inclure dans un commit.**
- `backend/.env` est modifié mais **non versionné** (`.gitignore`) : c'est le
  réglage local, seul `.env.example` est versionné.
