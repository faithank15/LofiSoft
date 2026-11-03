# Carte du code

Un fichier, un rôle. Généré à partir des commentaires du code ; une ligne vide veut dire que le fichier n'a pas de commentaire de tête (le nom suffit).

## Application mobile (`mobile/lib`)

### `./`

- `app.dart`
- `main.dart`

### `core/constants/`

- `app_config.dart` — Configuration injectée à la compilation, jamais écrite en dur.
- `app_constants.dart` — Constantes techniques de l'application.

### `core/errors/`

- `app_exception.dart` — Exceptions applicatives : les couches basses les lèvent, les contrôleurs les attrapent

### `core/logging/`

- `app_logger.dart` — **fichier vide** (prévu au squelette, jamais écrit)

### `core/theme/`

- `app_colors.dart` — Palette officielle LofiSoft (direction artistique v2, celle des maquettes).
- `app_radius.dart` — Rayons de courbure. Un seul endroit, pour que tous les coins soient cohérents.
- `app_shadows.dart` — Ombres LofiSoft : toujours LÉGÈRES et floues. Jamais d'ombre dure ni colorée
- `app_spacing.dart` — Grille d'espacement : on n'invente pas de valeurs, on prend dans cette liste.
- `app_text_styles.dart` — Styles de texte LofiSoft, police Plus Jakarta Sans.
- `app_theme.dart` — GetMaterialApp(theme: AppTheme.light, ...)

### `core/utils/`

- `cloudinary.dart` — Aide pour les images hébergées sur Cloudinary.
- `currency_formatter.dart` — Formatage des montants en francs CFA : `75 000 FCFA`.
- `date_format.dart` — Formatage court et lisible des dates en français, sans dépendance externe.
- `json_utils.dart` — Conversions sûres de données JSON dynamiques.
- `validators.dart` — Fonctions de validation des champs de saisie.

### `data/cache/`

- `app_storage.dart` — Cache local de l'application : indicateurs de première ouverture et données
- `auth_storage.dart` — Session active conservée sur le téléphone : jeton, rôle et profil.

### `data/remote/`

- `api_client.dart` — Client HTTP unique de l'application.

### `data/remote/fakes/`

- `fake_admin_service.dart` — Service simulé de l'espace administrateur (`USE_FAKE_API=true`).
- `fake_announcement_service.dart` — FAUX service d'annonces, pour développer sans API.
- `fake_auth_service.dart` — FAUX service d'authentification, pour développer l'interface sans API.
- `fake_owner_dashboard_service.dart` — FAUX service du tableau de bord propriétaire (USE_FAKE_API=true).
- `fake_property_service.dart` — Service simulé de gestion des logements pour le mode sans serveur (`USE_FAKE_API=true`).
- `fake_rental_service.dart` — FAUX service de location, pour développer sans API.
- `fake_upload_service.dart` — FAUX envoi d'image : ne contacte personne, renvoie une URL factice.

### `data/remote/services/`

- `admin_service.dart` — Appels HTTP bruts de l'espace administrateur (signalements et vérifications d'identité).
- `announcement_service.dart` — Appels HTTP bruts des annonces et des favoris. Renvoie le JSON du serveur.
- `auth_service.dart` — Appels HTTP bruts d'authentification. Ne décide de rien : renvoie le JSON du serveur.
- `owner_dashboard_service.dart` — Appels HTTP bruts de l'espace propriétaire (tableau de bord et loyers).
- `payment_service.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `property_service.dart` — Appels HTTP bruts pour la gestion des logements par le propriétaire.
- `rental_service.dart` — Appels HTTP bruts du code logement et de la location du locataire.
- `report_service.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `upload_service.dart` — Envoi d'une image au serveur, qui renvoie son URL (`{ "url": "..." }`).

### `data/repo/`

- `admin_repository.dart` — Source de vérité de l'espace administrateur.
- `announcement_repository.dart` — Source de vérité des annonces et des favoris pour les contrôleurs.
- `auth_repository.dart` — Source de vérité de l'authentification pour les contrôleurs.
- `identity_repository.dart` — Vérification d'identité du propriétaire (badge « Vérifié »).
- `owner_announcement_repository.dart` — Ce que le propriétaire saisit pour une nouvelle annonce (écrans C3 et C4).
- `owner_dashboard_repository.dart` — Source de vérité du tableau de bord propriétaire.
- `payment_repository.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `property_repository.dart` — Dépôt unique pour la gestion des logements du bailleur avec persistance hors-ligne.
- `rental_repository.dart` — Source de vérité du code logement et de la location du locataire.
- `report_repository.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `tenant_rent_repository.dart` — Données de l'écran « Mon loyer », avec repli sur la dernière réponse reçue hors connexion.

### `di/`

- `injector.dart` — Point de composition : enregistre les singletons d'infrastructure.

### `domain/models/`

- `admin_model.dart` — Un signalement (une ligne de GET /admin/reports).
- `announcement_model.dart` — Annonce telle que l'API la renvoie (fil, détail, favoris).
- `enums.dart` — Énumérations métier (alignées sur le diagramme de classes et l'API).
- `installment_model.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `models.dart`
- `owner_dashboard_model.dart` — « Novembre »
- `owner_profile_model.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `property_model.dart` — Détails d'une location active liée à un logement.
- `receipt_model.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `rental_model.dart` — Logement retrouvé grâce à son code, avant que le locataire confirme (écran B1).
- `rental_unit_model.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `report_model.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `search_preferences.dart` — Critères choisis par le locataire pendant l'onboarding (E2, E3, E4).
- `tenant_rent_model.dart` — Où en est le locataire (réponse de GET /me/situation).
- `user_model.dart` — Utilisateur de la plateforme (locataire, propriétaire ou administrateur).

### `presentation/components/atoms/`

- `app_avatar.dart`
- `app_back_button.dart` — Atome officiel LofiSoft de retour arrière.
- `app_button.dart`
- `app_card.dart` — Conteneur blanc standard LofiSoft avec bordure fine et ombre portée douce.
- `app_checkbox.dart` — Case à cocher de LofiSoft : carré arrondi (ou rond avec `round: true`).
- `app_chip.dart` — Choix sélectionnable en forme de pilule (type de logement, nombre de pièces, filtres).
- `app_divider.dart` — Séparateur visuel fin standardisé LofiSoft.
- `app_logo.dart` — AppLogo(size: 36)                 // sur fond clair : carré vert
- `app_network_image.dart` — Image distante (photos d'annonces) : nette sur mobile, légère en données, mise en cache.
- `app_text_field.dart` — Champ de saisie de LofiSoft : libellé au-dessus, cadre blanc, bordure verte au focus.
- `app_wordmark.dart` — Nom de la marque : « Lofi » + « Soft » (deux couleurs).
- `choice_illustration.dart` — Profils illustrés dans l'onboarding.
- `dashed_border.dart` — Cadre en pointillés autour d'un contenu (zone « ajouter une photo », boîte du code logement).
- `housing_illustration.dart` — Types de logements dessinés.
- `progress_bar.dart` — Barre de progression linéaire (loyer payé sur loyer dû). Se remplit en s'animant.
- `screen_title.dart` — Atome d'en-tête d'écran affichant un titre hiérarchique et un sous-titre optionnel.
- `skyline_band.dart` — Frise décorative de toits de maisons (la « ville » de LofiSoft).
- `status_text.dart` — Famille de couleur d'un statut.
- `step_progress_bar.dart` — Indicateur d'étapes : des segments dont les `current` premiers sont colorés.

### `presentation/components/molecules/`

- `admin_action_card.dart` — Carte d'administration : une étiquette de motif, un titre, un contenu facultatif
- `amount_field.dart` — Gros champ pour saisir le montant à payer (chiffres seulement, suffixe FCFA).
- `app_bottom_nav.dart` — Un onglet de la barre de navigation.
- `auth_header.dart` — Bandeau vert profond du haut des écrans Connexion et Inscription :
- `bottom_cta_bar.dart` — Zone d'action basse : bouton principal et, en dessous, une action secondaire.
- `budget_input.dart` — Double champ « budget minimum / maximum » en FCFA (chiffres seulement).
- `code_input.dart` — Formate la saisie du code logement : majuscules, lettres et chiffres seulement,
- `housing_code_box.dart` — Boîte qui affiche le code unique d'un logement, avec un bouton pour le partager.
- `housing_scene.dart` — Scène d'illustration d'un logement (maquettes E1 et E3).
- `id_preview.dart` — Aperçu côte à côte de la pièce d'identité et du selfie d'un propriétaire à vérifier.
- `illustration_panel.dart` — Grand panneau coloré qui présente une illustration, avec un titre et une légende.
- `info_row.dart` — Ligne « libellé à gauche, valeur à droite » (loyer, date limite, caution...).
- `listing_card.dart` — Carte d'annonce : photo, prix par mois, type, lieu, badge « Propriétaire vérifié » et cœur.
- `offline_banner.dart` — Bandeau affiché en haut de l'écran quand il n'y a pas de connexion.
- `onboarding_footer.dart` — Barre d'action basse des écrans d'onboarding (maquettes E2 → E4).
- `onboarding_step_header.dart` — En-tête commun des étapes d'onboarding (E2 → E4).
- `onboarding_title.dart` — Titre + sous-titre d'un écran d'onboarding (maquettes E2 → E4).
- `onboarding_top_nav.dart` — Barre haute commune aux écrans d'onboarding.
- `operator_card.dart` — Choix de l'opérateur Mobile Money (MTN Mobile Money, Moov Money).
- `owner_illustration_panel.dart` — Types d'illustrations intégrées dédiées à l'onboarding propriétaire.
- `owner_step_list.dart` — Données décrivant une étape au sein de la [OwnerStepList].
- `payment_row.dart` — Ligne d'historique : pastille de date, montant et opérateur Mobile Money.
- `photo_picker.dart` — Une photo de l'annonce : soit déjà en ligne (`url`), soit choisie sur le téléphone (`localPath`).
- `profile_illustration.dart`
- `receipt_summary.dart` — Ligne de détail d'un reçu.
- `rent_card.dart` — Carte du loyer du mois : montant restant à payer en grand, barre de progression, échéance.
- `rent_gauge.dart` — Jauge des loyers du mois, à placer sur fond vert profond.
- `role_segment.dart` — Une option du sélecteur : un titre et une courte phrase.
- `select_card.dart` — Grande carte de choix (profil, ville, type de logement). Bordure verte et coche quand choisie.
- `selection_check.dart` — Pastille de validation circulaire 26 px (maquettes E3 et E4).
- `selection_chip.dart` — Pastille de sélection (ville, quartier) — maquette E2.
- `step_list.dart` — Une étape de la liste d'accompagnement.
- `tenant_tile.dart` — Ligne descriptive d'un locataire : initiales, nom, logement et statut du loyer.

### `presentation/components/skeletons/`

- `auth_scaffold.dart` — Page de base de la Connexion et de l'Inscription : bandeau vert profond en haut
- `onboarding_scaffold.dart` — Squelette des écrans « parcours » (profil locataire, ajout d'un logement, etc.) :
- `splash_view.dart` — Écran de lancement animé (environ 2,2 secondes) :

### `presentation/features/admin/`

- `admin_binding.dart` — Injection des dépendances du lot 9 (signalements et vérifications d'identité).
- `admin_controller.dart` — Contrôleur de l'administrateur : signalements (D1) et vérifications d'identité (D2).
- `admin_dialogs.dart` — Barre du bas de l'administrateur, commune aux deux écrans.
- `admin_reports_page.dart` — D1 : signalements d'annonces à traiter.
- `admin_shell.dart` — Squelette commun de D1 et D2 : titre, sous-titre, liste tirable pour actualiser,
- `admin_users_page.dart` — Gestion des comptes : suspendre ou réactiver un utilisateur.
- `admin_verifications_page.dart` — D2 : demandes de badge « Vérifié » des propriétaires.

### `presentation/features/auth/`

- `auth_binding.dart` — Utilisé par les routes /login et /register.
- `auth_controller.dart` — Logique des écrans Connexion (A5) et Inscription (A6).
- `forgot_password_page.dart` — Mot de passe oublié : on saisit son e-mail, le serveur envoie un lien.
- `login_controller.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `login_page.dart` — A5  Connexion.
- `register_controller.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `register_page.dart` — A6 : Inscription.

### `presentation/features/dev/`

- `dev_menu_page.dart` — Menu TEMPORAIRE de développement : un bouton par écran.

### `presentation/features/listings/`

- `favorites_page.dart` — Favoris · A4 · annonces enregistrées.
- `listing_binding.dart` — Binding du fil (A1) et des favoris (A4). Le service est faux avec USE_FAKE_API.
- `listing_details_controller.dart` — Détail d'une annonce (A3). L'identifiant vient du chemin : /listings/details/:id.
- `listing_details_page.dart` — Couleurs de la maquette A3.
- `listing_form_binding.dart` — Injection de la création d'annonce (C3 et C4). ApiClient et AppStorage sont déjà enregistrés.
- `listing_form_controller.dart` — Logique de la création d'annonce en deux étapes (C3 : où ? ; C4 : prix et photos).
- `listing_form_page.dart` — C3 et C4 : nouvelle annonce en deux étapes (où ? puis prix et photos).
- `listings_controller.dart` — Fil d'annonces (A1) et favoris (A4).
- `listings_feed_page.dart` — Accueil · A1 · liste des annonces.

### `presentation/features/onboarding/`

- `budget_binding.dart` — Injection des dépendances de l'écran E4.
- `budget_controller.dart` — Contrôleur de l'écran E4 (choix du budget — locataire).
- `budget_page.dart` — Écran E4 · Locataire 3 : budget (choix du budget mensuel).
- `onboarding_binding.dart` — Injecteur de dépendances du module d'onboarding propriétaire (E5 à E7).
- `onboarding_completion.dart` — Point de sortie commun aux deux parcours d'onboarding.
- `onboarding_controller.dart` — Contrôleur GetX gérant l'état et les transitions de l'onboarding.
- `owner_onboarding_page.dart` — Écran d'onboarding propriétaire assemblant les maquettes E5, E6 et E7.
- `tenant_onboarding_page.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `type_binding.dart` — Injection des dépendances de l'écran E3.
- `type_controller.dart` — Contrôleur de l'écran E3 (choix du type de logement — locataire).
- `type_page.dart` — Écran E3 · Locataire 2 : type (choix du type de logement).
- `ville_binding.dart` — Injection des dépendances de l'écran E2.
- `ville_controller.dart` — Contrôleur de l'écran E2 (choix de ville et quartiers — locataire).
- `ville_page.dart` — Écran E2 · Locataire 1 : où ? (choix de ville et de quartiers).
- `welcome_binding.dart` — Injection des dépendances de l'écran d'accueil E1.
- `welcome_controller.dart` — Contrôleur de l'écran d'accueil E1 (choix de profil).
- `welcome_page.dart` — Écran E1 · Bienvenue : profil (onboarding locataire / propriétaire).

### `presentation/features/owner_dashboard/`

- `owner_dashboard_binding.dart` — Injection des dépendances du lot 7 (tableau de bord et loyers propriétaire).
- `owner_dashboard_controller.dart` — Contrôleur du tableau de bord propriétaire (C1) et des loyers du mois (C7).
- `owner_dashboard_page.dart` — C1 : accueil du propriétaire.
- `owner_dashboard_view.dart` — Texte et couleur d'un statut de loyer.
- `owner_rents_page.dart` — C7 : loyers du mois.

### `presentation/features/owner_properties/`

- `housing_create_page.dart` — Nouveau logement (bouton « + Ajouter » de C2). Le logement reçoit son code à la création ;
- `property_binding.dart` — Injection des dépendances du Lot 8 (Logements propriétaire).
- `property_controller.dart` — Contrôleur GetX gérant l'état et les flux d'actions pour le Lot 8 (Logements propriétaire).
- `property_detail_page.dart` — Écran C5 : Détail d’un logement.
- `property_form_page.dart` — Écran C6 : Ajouter un locataire (maquette C6-Ajouter-locataire.html).
- `property_list_page.dart` — Écran C2 : Mes logements (catalogue des biens du propriétaire).

### `presentation/features/payment/`

- `payment_binding.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `payment_checkout_page.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `payment_controller.dart` — **fichier vide** (prévu au squelette, jamais écrit)
- `receipt_details_page.dart` — **fichier vide** (prévu au squelette, jamais écrit)

### `presentation/features/profile/`

- `profile_binding.dart` — Injection de la page Profil. ApiClient et AuthStorage sont déjà enregistrés au démarrage.
- `profile_controller.dart` — Contrôleur de la page Profil (locataire, propriétaire et administrateur).
- `profile_page.dart` — Profil : identité du compte et déconnexion.

### `presentation/features/rent_tracking/`

- `payment_history_page.dart` — Mes paiements · B5 : l'historique, regroupé par mois de loyer.
- `rent_tracking_binding.dart` — Injection de « Mon loyer » et de l'historique. ApiClient, AuthStorage et AppStorage sont déjà enregistrés.
- `rent_tracking_controller.dart` — Situation d'un mois de loyer.
- `rent_tracking_page.dart` — Mon loyer · B2 (en ligne) et B6 (hors ligne) : même page, deux états.

### `presentation/features/rental/`

- `join_housing_binding.dart`
- `join_housing_controller.dart` — Écran B1 « Rejoindre mon logement » : saisie du code, aperçu du logement, confirmation.
- `join_housing_page.dart` — B1 Rejoindre mon logement.

### `presentation/features/splash/`

- `splash_binding.dart`
- `splash_controller.dart` — Écran de lancement (E0) : laisse l'animation se jouer, regarde la session en cache,
- `splash_page.dart` — E0 · Lancement. Aucun champ de texte : GetView suffit.

### `presentation/routes/`

- `app_pages.dart` — Table reliant chaque route à sa page et à son binding d'injection.
- `app_routes.dart` — Noms de toutes les routes de l'application. Aucune chaîne en dur ailleurs :
- `auth_middleware.dart` — Garde de route : une page protégée n'est ouverte qu'avec une session.
- `role_middleware.dart` — Page d'accueil de chaque rôle.

### `presentation/shared/`

- `empty_view.dart` — État vide : une icône et une phrase (ex. « Aucun favori pour l'instant »).
- `error_view.dart` — Erreur avec message et bouton « Réessayer ».
- `load_status.dart` — État de chargement d'un écran, observé par les pages avec Obx.
- `loading_view.dart` — Chargement centré, à placer dans le corps d'une page.
- `placeholder_page.dart` — Page TEMPORAIRE pour les routes que les autres membres n'ont pas encore écrites.

## Backend (`backend`)

### `app/Http/Controllers/Api/`

- `AdminController.php`
- `AnnouncementController.php`
- `AuthController.php`
- `HousingController.php`
- `OwnerDashboardController.php`
- `PaymentController.php`
- `RentalController.php`
- `UploadController.php`

### `app/Http/Middleware/`

- `EnsureActiveAccount.php` — Un compte suspendu perd l'accès immédiatement (401 : le mobile efface alors sa session).
- `EnsureRole.php`

### `app/Http/Requests/`

- `Auth/LoginRequest.php`
- `Auth/RegisterRequest.php`

### `app/Http/Resources/`

- `AnnouncementResource.php`
- `UserResource.php`

### `app/Models/`

- `Announcement.php`
- `AnnouncementPhoto.php`
- `Housing.php`
- `IdentityRequest.php`
- `Payment.php`
- `RentPeriod.php`
- `Rental.php`
- `Report.php`
- `User.php`

### `app/Enums/`

- `AccommodationType.php`
- `AnnouncementStatus.php`
- `IdentityStatus.php`
- `Operator.php`
- `PaymentStatus.php`
- `RentStatus.php`
- `RentalStatus.php`
- `ReportStatus.php`
- `UserRole.php`

### `app/Services/`

- `CloudinaryService.php`
- `ImageStorage.php` — Stocke une image et renvoie son URL publique. Cloudinary si CLOUDINARY_URL est renseigné, disque local `public` sinon (dev).
- `RentBalance.php` — Calcul du solde d'une période de loyer : dû (loyer + report) moins paiements réussis.

### `app/Console/Commands/`

- `RolloverRentPeriods.php`

### `database/migrations/`

- `0001_01_01_000000_create_users_table.php`
- `0001_01_01_000001_create_cache_table.php`
- `0001_01_01_000002_create_jobs_table.php`
- `2026_10_22_211513_create_personal_access_tokens_table.php`
- `2026_10_28_162258_create_housings_table.php`
- `2026_10_28_162300_create_rentals_table.php`
- `2026_10_28_162302_create_rent_periods_table.php`
- `2026_10_28_162304_create_payments_table.php`
- `2026_10_28_162306_create_announcements_table.php`
- `2026_10_28_162307_create_announcement_photos_table.php`
- `2026_10_28_162309_create_favorites_table.php`
- `2026_10_28_162311_create_identity_requests_table.php`
- `2026_10_28_162312_create_reports_table.php`

### `database/seeders/`

- `DatabaseSeeder.php` — Données de démonstration. Mot de passe de tous les comptes : Test1234.  Comptes (les trois premiers sont ceux du FakeAuthService du mobile) : locataire@lofi.bj   TENANT  location ACTIVE, loyer du mois payé en partie proprio@lofi.bj     OWNER   vérifié, 3 logements admin@lofi.bj       ADMIN locataire2@lofi.bj  TENANT  sans location : pour tester « Rejoindre mon logement » proprio2@lofi.bj    OWNER   non vérifié, demande d'identité en attente  Codes logement : M4T-83P (loué), K7F-29X (libre), P9Q-55D (libre).

### `routes/`

- `api.php`
- `console.php`
- `web.php`

### `tests/Feature/`

- `AdminTest.php`
- `AnnouncementTest.php`
- `FavoriteAndReportTest.php`
- `HousingTest.php`
- `OwnerTest.php`
- `PaymentTest.php`
- `RentalTest.php`
- `RoleMiddlewareTest.php` — Matrice routes × rôles : chaque route protégée refuse les rôles non prévus.
- `RolloverCommandTest.php`
- `SeederIntegrityTest.php` — Les comptes et codes documentés dans backend/docs doivent exister et fonctionner.
- `UploadTest.php`

### `tests/Support/`

- `BuildsData.php`

## Tests mobile (`mobile/test`)

### `test/`

- `api_contract_test.dart`
- `onboarding_goldens_test.dart`
- `onboarding_test.dart`
- `widget_test.dart`

### `test/admin/`

- `admin_test.dart`

### `test/core/`

- `api_client_test.dart`
- `utils_test.dart`

### `test/data/`

- `repositories_test.dart`

### `test/domain/`

- `models_test.dart`

### `test/owner/`

- `housing_create_test.dart`
- `listing_form_test.dart`
- `owner_test.dart`
- `requests_test.dart`

### `test/presentation/`

- `bindings_test.dart`
- `controllers_test.dart`
- `route_guards_test.dart`

### `test/support/`

- `app_fonts.dart`
- `fakes.dart`

### `test/tenant/`

- `tenant_rent_test.dart`
