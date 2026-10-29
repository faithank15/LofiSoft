# Architecture Logicielle et Guide de Développement — LofiSoft Mobile

Ce document constitue la référence technique officielle de l'application mobile LofiSoft. Il détaille le rôle de chaque dossier et fichier, le flux de données entre l'API REST et l'interface, ainsi que les règles strictes d'utilisation du framework GetX.

---

## 1. Vue d'Ensemble de l'Architecture

L'application adopte une architecture modulaire fluide, orientée fonctionnalités (*Feature-Driven*), découplée et réactive avec GetX.

```
Flux de données unidirectionnel :

[ Interface Utilisateur (Pages / Obx) ]
                 |
                 v
       [ GetxController ]
                 |
                 v
        [ Repositories ]  <--->  [ Cache Local (GetStorage) ]
                 |
                 v
   [ Remote Services (HTTP) ]
                 |
                 v
        [ ApiClient (Base) ]
                 |
                 v
    [ Serveur API Laravel REST ]
```

### Principes directeurs :
1. **Séparation stricte** : L'interface consomme des contrôleurs GetX, qui consomment des dépôts (*repositories*), qui consomment des services HTTP et le cache.
2. **Modèles unifiés** : Les classes de `domain/models/` sont les seuls objets de données manipulant le JSON (`fromJson`, `toJson`).
3. **Composants atomiques passifs** : Tous les composants graphiques de `presentation/components/` sont des `StatelessWidget` purs. Ils ne connaissent aucun contrôleur GetX.

---

## 2. Cartographie Complète des Dossiers et Fichiers

### 2.1 Racine `lib/`
- `main.dart` : Point d'entrée de l'application. Initialise le stockage synchrone (`GetStorage`), délègue l'enregistrement des singletons d'infrastructure à `initializeDependencies()`, et démarre l'application.
- `app.dart` : Déclare l'instance principale `GetMaterialApp`, configure la charte graphique globale (thème clair/sombre), et applique la table des routes.

#### `di/`
Le dossier `di/` vit **à la racine de `lib/`**, hors des couches `core/`, `data/`, `domain/` et `presentation/`. C'est le point de composition de l'application : il est le seul endroit autorisé à relier entre elles les briques d'infrastructure, ce qui garantit qu'aucune couche ne dépend d'une couche supérieure (en particulier, `core/` ne dépend jamais de `data/`).

- `injector.dart` : Fonction `initializeDependencies()` qui enregistre les singletons d'infrastructure (`AuthStorage`, `AppStorage`, `ApiClient`) via `Get.put(..., permanent: true)`. Appelée une seule fois depuis `main.dart`, après `GetStorage.init()`.

---

### 2.2 Socle Technique : `lib/core/`
Ce dossier contient tout le code transverse réutilisable, indépendant de toute logique métier spécifique.

#### `core/constants/`
- `app_config.dart` : Configuration injectée à la compilation via `--dart-define` (ex. `API_BASE_URL`, timeouts réseau). Ne contient aucun secret en dur.
- `app_constants.dart` : Constantes techniques de l'application (indicatif téléphonique `+229`, devise `FCFA`, durées par défaut).

#### `core/errors/`
- `app_exception.dart` : Hiérarchie scellée des exceptions applicatives (`NetworkException`, `UnauthorizedException`, `ValidationException`, `ServerException`). Permet d'afficher des messages compréhensibles à l'utilisateur sans exposer d'erreur brute.

#### `core/logging/`
- `app_logger.dart` : Journalisation conditionnelle. N'imprime des logs qu'en mode débogage (`kDebugMode`). Ne journalise jamais les mots de passe, tokens JWT ni données sensibles.

#### `core/theme/` (Fondations du Design System)
- `app_colors.dart` : Palette officielle LofiSoft (Vert Lofi `#0F5C4D`, Ambre `#F2B134`, Vert profond `#12211D`, Gris vert `#4F625C`, Brume `#F4F8F6`, Trait `#D5E2DC`).
- `app_radius.dart` : Constantes de rayons de courbure pour les cartes, champs et boutons.
- `app_shadows.dart` : Définitions standardisées des ombres portées et élévations.
- `app_spacing.dart` : Grille d'espacement uniforme (marges, paddings, gaps entre widgets).
- `app_text_styles.dart` : Définitions typographiques complètes basées sur la police *Plus Jakarta Sans*.
- `app_theme.dart` : Assemblage des thèmes `ThemeData` Material 3 (clair et sombre).

#### `core/utils/`
Helpers purs, sans aucune dépendance vers `data/`, `domain/` ou `presentation/`.
- `cloudinary.dart` : Construction des URL d'images Cloudinary à partir des clés de transformation.
- `currency_formatter.dart` : Formatage strict des montants en Francs CFA (ex: `75 000 FCFA`).
- `date_format.dart` : Formatage court et lisible des dates en français sans dépendance lourde.
- `json_utils.dart` : Fonctions utilitaires sécurisant la conversion de payloads dynamiques (`asJsonMap`, `asJsonList`).
- `validators.dart` : Fonctions de validation pour champs de saisie (e-mail valide, numéro béninois `+229`, mot de passe fort, champ obligatoire).

---

### 2.3 Couche Données : `lib/data/`
Gère l'accès direct aux données distantes (API REST Laravel sur Render) et la persistance locale hors-ligne.

#### `data/cache/`
- `auth_storage.dart` : Persistance de la session active (jeton JWT d'accès, rôle utilisateur, profil en cache) via `GetStorage`.
- `app_storage.dart` : Moteur de cache local permettant la consultation hors-ligne (stockage des dernières échéances de loyer, historique récent des reçus et coordonnées du propriétaire).

#### `data/remote/`
- `api_client.dart` : Client HTTP unique de l'application, basé sur `http`. Gère l'injection systématique du jeton d'authentification Bearer, intercepte les retours HTTP 401 pour déconnecter la session expirée, et applique le timeout réseau. Il est placé dans la couche `data` (et non dans `core/`) car il dépend du cache de session `AuthStorage` : le noyau transverse `core/` ne doit jamais dépendre de la couche données.

#### `data/remote/fakes/`
Implémentations simulées des services distants, activables **sans serveur** via `--dart-define=USE_FAKE_API=true` (voir `AppConfig.useFakeApi` et `AuthBinding`).
- `fake_auth_service.dart` : Simule l'authentification (connexion, inscription) avec une latence artificielle et des comptes de test (`locataire@lofi.bj`, `proprio@lofi.bj`, `admin@lofi.bj` — mot de passe `Test1234`). Le `repository` sous-jacent reste le vrai : il ne contient aucune donnée simulée.

#### `data/remote/services/`
Classes dérivées de `GetxService` effectuant les requêtes HTTP brutes via `ApiClient` :
- `auth_service.dart` : Endpoints `/auth/login`, `/auth/register`, `/auth/me`, `/auth/refresh`, mot de passe oublié.
- `announcement_service.dart` : Consultation du flux d'annonces, filtres par quartier/budget, publication d'annonce avec photos.
- `property_service.dart` : Création et gestion des propriétés immobilières et des espaces louables associés.
- `rental_service.dart` : Gestion des contrats de location, assignation de locataire via code logement, consultation des échéances.
- `payment_service.dart` : Initiation du paiement Mobile Money MTN/Moov via l'agrégateur KKiaPay, interrogation de statut de transaction.
- `report_service.dart` : Signalement d'annonces abusives auprès de l'administrateur.

#### `data/repo/`
Les dépôts orchestrent les services distants et le cache local. Ils constituent la seule source de vérité consommée par les contrôleurs GetX :
- `auth_repository.dart` : Orchestre la connexion, enregistre le token dans `AuthStorage`, vide la session à la déconnexion.
- `announcement_repository.dart` : Récupère les annonces réseau, gère la pagination et met en cache les annonces favorites.
- `property_repository.dart` : Gère le CRUD des biens du propriétaire.
- `rental_repository.dart` : Synchronise les baux et leurs échéances. En cas d'échec réseau, renvoie les données stockées dans `AppStorage` pour satisfaire la spécification hors-ligne.
- `payment_repository.dart` : Déclenche les flux de paiement et sauvegarde les reçus générés en local.
- `report_repository.dart` : Traite les signalements et modérations.

---

### 2.4 Modèles Métier : `lib/domain/models/`
Contient l'ensemble des structures de données dérivées du diagramme de classes UML.

- `enums.dart` : Définition de toutes les énumérations :
  - `UserRole` (`TENANT`, `OWNER`, `ADMIN`)
  - `RentalStatus` (`PENDING`, `ACTIVE`, `FINISHED`)
  - `AnnouncementStatus` (`DRAFT`, `PUBLISHED`, `CANCELED`, `CLOSED`)
  - `AccommodationType` (`HOUSE`, `ROOM`, `OTHER`)
  - `ReportStatus` (`PENDING`, `RESOLVED`, `DISMISSED`)
- `models.dart` : Fichier de commodité exportant l'ensemble des modèles du dossier.
- `user_model.dart` : Modèle de l'utilisateur (`id`, `nom`, `prenoms`, `email`, `telephone`, `role`, `actif`).
- `owner_profile_model.dart` : Profil spécifique du bailleur lié au compte utilisateur.
- `property_model.dart` : Propriété physique (`nom`, `description`, `adresse`, `nombreChambre`).
- `rental_unit_model.dart` : Espace louable (`description`, `adresse`, `type`, `loyerMensuel`, `estDisponible`).
- `announcement_model.dart` : Annonce publiée avec loyer, statut, date et liste des `PhotoAnnonce`.
- `rental_model.dart` : Contrat de location unissant un locataire à un espace louable.
- `installment_model.dart` : Échéance de loyer (`dateDebut`, `dateFin`, `estSolde`).
- `payment_model.dart` : Transaction de paiement (`montant`, `datePaiement`, `reference`, `estPaye`).
- `receipt_model.dart` : Reçu de loyer généré après transaction (`dateEmission`, `montantPaye`, `details`).
- `report_model.dart` : Signalement d'annonce (identifiants `reporterId` et `reportedId` typés en UUID/String).

---

### 2.5 Couche Présentation : `lib/presentation/`

#### `presentation/components/` (Design System Atomique)
Conformément au document `LofiSoft-composants.pdf`, ces composants sont **100 % passifs** (`StatelessWidget`). Ils reçoivent leurs données et leurs callbacks d'action en paramètres.

- `atoms/` (16 éléments unitaires) :
  - `app_avatar.dart` : Pastille avec initiales de l'utilisateur.
  - `app_back_button.dart` : Flèche de retour standardisée.
  - `app_button.dart` : Bouton d'action principal (états normal, chargement, désactivé).
  - `app_card.dart` : Conteneur blanc avec ombre légère.
  - `app_checkbox.dart` : Case à cocher pour sélection et conditions générales.
  - `app_chip.dart` : Filtres sélectionnables (nombre de pièces, type de bien).
  - `app_divider.dart` : Séparateur visuel fin.
  - `app_logo.dart` : Logo graphique officiel "Maison L".
  - `app_text_field.dart` : Champ de saisie avec libellé, focus, préfixe (+229) et suffixe (FCFA).
  - `app_wordmark.dart` : Typographie de marque "LofiSoft".
  - `choice_illustration.dart` : Visuels vectoriels de choix de profil.
  - `progress_bar.dart` : Barre de progression linéaire du loyer réglé.
  - `screen_title.dart` : En-tête de page avec titre et sous-titre stylisés.
  - `skyline_band.dart` : Frise graphique décorative de toits de maisons.
  - `status_text.dart` : Badge textuel coloré (Payé, Partiel, En retard, Loué, Libre).
  - `step_progress_bar.dart` : Indicateur d'étapes (1/3, 2/3, 3/3).

- `molecules/` (22 assemblages) :
  - `auth_header.dart` : Bandeau supérieur vert avec logo et ligne de toits.
  - `role_segment.dart` : Sélecteur à bascule Locataire / Propriétaire.
  - `code_input.dart` : Champ de saisie segmenté pour code logement.
  - `select_card.dart` : Grande carte interactive de sélection de profil ou de ville.
  - `budget_input.dart` : Double champ de budget minimum et maximum en FCFA.
  - `bottom_cta_bar.dart` : Barre fixe en bas d'écran avec bouton principal et lien retour.
  - `step_list.dart` : Liste verticale d'étapes d'accompagnement.
  - `illustration_panel.dart` : Panneau illustré de présentation.
  - `listing_card.dart` : Carte d'annonce avec photo, prix en FCFA, localisation et badge.
  - `app_bottom_nav.dart` : Barre de navigation inférieure adaptée selon le profil (Locataire, Bailleur, Admin).
  - `rent_card.dart` : Carte synthétique du loyer du mois, montant restant et progression.
  - `payment_row.dart` : Ligne d'historique de paiement (date, montant, opérateur).
  - `operator_card.dart` : Sélecteur d'opérateur Mobile Money (MTN Mobile Money, Moov Money).
  - `amount_field.dart` : Champ monétaire dédié à la saisie du montant à verser.
  - `receipt_summary.dart` : Carte récapitulative détaillée d'un reçu de paiement.
  - `rent_gauge.dart` : Jauge visuelle animée comparant les loyers perçus aux loyers attendus.
  - `tenant_tile.dart` : Ligne descriptive d'un locataire, de son logement et de son statut.
  - `housing_code_box.dart` : Boîte affichant le code unique du logement avec bouton copier/partager.
  - `info_row.dart` : Ligne simple libellé / valeur pour les détails techniques.
  - `photo_picker.dart` : Sélecteur d'images permettant d'uploader jusqu'à 10 photos d'annonce.
  - `admin_action_card.dart` : Carte d'action d'administration (Valider / Refuser / Supprimer).
  - `id_preview.dart` : Aperçu sécurisé de pièce d'identité pour validation.

- `skeletons/` (3 gabarits de mise en page réutilisables) :
  - `auth_scaffold.dart` : Structure de base pour connexion et inscription (bandeau vert + panneau papier blanc arrondi).
  - `onboarding_scaffold.dart` : Structure avec barre d'étapes supérieure, contenu déroulant et CTA fixe en bas.
  - `splash_view.dart` : Écran d'accueil et d'animation de démarrage.

#### `presentation/features/` (Modules Métier de l'Application)
Chaque fonctionnalité est strictement autonome dans son répertoire et comporte :
1. Sa page principale (`_page.dart`).
2. Son contrôleur d'état (`_controller.dart`).
3. Son injecteur de dépendances (`_binding.dart`).

- `admin/` : Gestion des signalements et modération des annonces par l'administrateur.
- `auth/` : Écrans de connexion, d'inscription et de réinitialisation de mot de passe.
- `dev/` : Menu de développement, accessible uniquement en mode fake API (`/dev`). Regroupe les raccourcis vers les écrans en construction.
- `listings/` : Consultation du catalogue d'annonces, recherche par filtres et formulaire de publication de logement.
- `onboarding/` : Parcours guidé de première ouverture différencié pour locataires et propriétaires.
- `owner_dashboard/` : Vue synthétique du bailleur (jauge d'encaissement des loyers, alertes impayés). `owner_dashboard_page.dart` est pour l'instant la page d'atterrissage temporaire qui valide la fin de l'onboarding, en attente du Lot 7.
- `owner_properties/` : Liste et gestion des propriétés et espaces louables du propriétaire.
- `payment/` : Parcours de règlement de loyer en ligne (KKiaPay MTN/Moov) et consultation des reçus.
- `rent_tracking/` : Espace locataire de suivi de l'échéance en cours, montants restants et paiements fractionnés.
- `splash/` : Contrôle de session au lancement et redirection vers l'écran approprié.

#### `presentation/routes/`
- `app_routes.dart` : Constantes de chaînes de caractères nommant toutes les routes de l'application (`/login`, `/listings`, `/rent-tracking`).
- `app_pages.dart` : Table liant chaque nom de route à sa page, à son `binding` dédié et à ses éventuels middlewares.
- `auth_middleware.dart` : Redirige vers `/login` si aucune session active n'est détectée.
- `role_middleware.dart` : Redirige dynamiquement l'utilisateur vers son espace dédié selon son rôle (`TENANT` -> Suivi loyer, `OWNER` -> Dashboard propriétaire, `ADMIN` -> Modération).

#### `presentation/shared/`
Composants transverses d'états d'écran :
- `load_status.dart` : Enumération `enum LoadStatus { initial, loading, loaded, failure }`.
- `loading_view.dart` : Widget centré de chargement adaptatif.
- `error_view.dart` : Widget d'affichage d'erreur avec message et bouton de nouvel essai.
- `empty_view.dart` : Widget affichant un état vide avec icône et libellé explicatif.

---

## 3. Guide Pratique d'Utilisation de GetX pour l'Équipe

Pour maintenir un code propre, performant et sans fuite mémoire, l'équipe doit appliquer rigoureusement les patrons suivants.

### 3.1 Gestion des dépendances : Les Bindings de Fonctionnalité

Chaque route applicative déclare **son propre binding** dans `app_pages.dart`. Le binding initialise uniquement les éléments dont la page a besoin.

Règle absolue d'enregistrement :
- **Couche Données (`Repository`, `Service`)** : Utiliser `Get.lazyPut(..., fenix: true)`. Le flag `fenix: true` permet à GetX de recréer l'instance si l'utilisateur y revient plus tard, tout en libérant la mémoire quand elle n'est plus active.
- **Contrôleur Métier (`GetxController`)** : Utiliser `Get.lazyPut(...)` sans `fenix`. Une instance neuve est créée à l'ouverture de l'écran et détruite automatiquement à sa fermeture.

**Singletons d'infrastructure** : `AuthStorage`, `AppStorage` et `ApiClient` ne sont enregistrés **que** par `initializeDependencies()` (`lib/di/injector.dart`), au démarrage de l'application. Aucun binding de fonctionnalité ne doit les ré-enregistrer.

**Choix du service réel ou simulé** : lorsqu'un service dispose d'une version fake (voir `data/remote/fakes/`), le binding sélectionne l'implémentation au moment de l'enregistrement, sur la base du mode de compilation :

```dart
Get.lazyPut<AuthService>(
  () => AppConfig.useFakeApi
      ? FakeAuthService(Get.find())
      : AuthService(Get.find()),
  fenix: true,
);
```

Avec `--dart-define=USE_FAKE_API=true`, l'application démarre sur la route `/dev` (menu de développement) et toute l'authentification est servie par `FakeAuthService`, sans appel réseau.

```dart
// Exemple : presentation/features/listings/listing_binding.dart
import 'package:get/get.dart';
import '../../../data/remote/services/announcement_service.dart';
import '../../../data/repo/announcement_repository.dart';
import 'listings_controller.dart';

class ListingBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Service distant (créé à la demande, réutilisable)
    Get.lazyPut<AnnouncementService>(
      () => AnnouncementService(),
      fenix: true,
    );

    // 2. Repository (injecte le service et le cache)
    Get.lazyPut<AnnouncementRepository>(
      () => AnnouncementRepository(Get.find(), Get.find()),
      fenix: true,
    );

    // 3. Contrôleur spécifique de l'écran (détruit quand on quitte la page)
    Get.lazyPut<ListingsController>(
      () => ListingsController(repository: Get.find()),
    );
  }
}
```

---

### 3.2 Contrôleurs Métier : La Règle d'Or des Formulaires

Un `GetxController` ne doit contenir **que de la logique métier et des variables réactives (`Rx`)**.

**Interdiction formelle** : Ne mettez jamais de `TextEditingController` ou de `GlobalKey<FormState>` dans un `GetxController`.
- *Raison technique* : Lorsqu'une page se ferme avec une animation, Flutter libère le contrôleur GetX avant la fin du rendu graphique du champ de texte. Cela déclenche l'erreur classique : `A TextEditingController was used after being disposed`.
- *Bonne pratique* : Les `TextEditingController` vivent dans le `State` d'un `StatefulWidget` (la page) et sont libérés dans la méthode `dispose()` de la page.

```dart
// Exemple : presentation/features/listings/listings_controller.dart
import 'package:get/get.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/repo/announcement_repository.dart';
import '../../../domain/models/announcement_model.dart';
import '../../shared/load_status.dart';

class ListingsController extends GetxController {
  ListingsController({required AnnouncementRepository repository})
      : _repository = repository;

  final AnnouncementRepository _repository;

  // Variables observables (se terminent par .obs)
  final RxList<AnnouncementModel> announcements = <AnnouncementModel>[].obs;
  final Rx<LoadStatus> status = LoadStatus.initial.obs;
  final RxnString errorMessage = RxnString();
  final RxnString selectedCity = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    status.value = LoadStatus.loading;
    errorMessage.value = null;

    try {
      final results = await _repository.getAnnouncements(city: selectedCity.value);
      announcements.assignAll(results);
      status.value = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      status.value = LoadStatus.failure;
    } catch (_) {
      errorMessage.value = 'Une erreur inattendue est survenue.';
      status.value = LoadStatus.failure;
    }
  }
}
```

---

### 3.3 Consommation Réactive dans la Page avec `GetView` et `Obx`

Pour lier une vue à son contrôleur :
1. Si la page ne possède aucun champ de formulaire : étendre `GetView<MonController>`.
2. Si la page gère des champs de texte : utiliser un `StatefulWidget` standard et récupérer le contrôleur via `final controller = Get.find<MonController>();`.
3. Encapsuler **uniquement** les parties de l'écran qui dépendent d'une variable `.obs` dans un widget `Obx(() => ...)`.

```dart
// Exemple : presentation/features/listings/listings_feed_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../components/molecules/listing_card.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'listings_controller.dart';

class ListingsFeedPage extends GetView<ListingsController> {
  const ListingsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logements disponibles')),
      body: Obx(() {
        // Switch exhaustif selon le statut de chargement
        return switch (controller.status.value) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(),
          LoadStatus.failure => ErrorView(
              message: controller.errorMessage.value ?? 'Erreur de chargement.',
              onRetry: controller.fetchAnnouncements,
            ),
          LoadStatus.loaded => RefreshIndicator(
              onRefresh: controller.fetchAnnouncements,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.announcements.length,
                itemBuilder: (context, index) {
                  final announcement = controller.announcements[index];
                  return ListingCard(
                    title: announcement.titre,
                    price: announcement.loyerMensuel,
                    location: announcement.description,
                    onTap: () => Get.toNamed('/listings/details/${announcement.id}'),
                  );
                },
              ),
            ),
        };
      }),
    );
  }
}
```

---

### 3.4 Navigation et Transmission d'Identifiants

**Règle absolue** : Les identifiants de ressources doivent voyager dans le chemin d'URL via des paramètres nommés (`/listings/details/:id`), et non dans des `Get.arguments` génériques non typés.

- Déclaration de route dans `app_pages.dart` :
  ```dart
  GetPage(
    name: '/listings/details/:id',
    page: () => const ListingDetailsPage(),
    binding: ListingBinding(),
  ),
  ```
- Navigation vers la page :
  ```dart
  Get.toNamed('/listings/details/${item.id}');
  ```
- Lecture de l'identifiant dans le contrôleur :
  ```dart
  final String itemId = Get.parameters['id'] ?? '';
  ```

---

### 3.5 Mode Hors-Ligne avec `GetStorage`

Pour respecter la spécification 3.5 (consultation du statut de loyer et des coordonnées sans connexion internet) :
1. Chaque appel réseau réussi enregistre la donnée brute dans `AppStorage`.
2. En cas de `NetworkException`, le repository lit le cache local et renvoie les dernières données connues.
3. Le contrôleur bascule sur ces données tout en notifiant l'utilisateur qu'il consulte une version hors-ligne.

---

### 3.6 Les 5 Anti-Patrons à Bannir Absolument

1. **Ne jamais appeler `Get.put()` à l'intérieur de la méthode `build()` d'un widget** : Cela instancie un nouveau contrôleur à chaque reconstruction graphique de Flutter.
2. **Ne jamais faire de navigation (`Get.toNamed`) depuis un service HTTP** : La couche réseau lève des exceptions typées. La décision de naviguer appartient exclusivement à la page ou au contrôleur.
3. **Ne jamais injecter de couleurs en dur dans les pages (`Colors.green`, `Color(0xFF...)`)** : Toujours utiliser `Theme.of(context).colorScheme` ou les tokens définis dans `AppColors`.
4. **Ne jamais stocker de valeurs simulées (mocks) au sein d'un repository de production** : Si l'API échoue et qu'aucun cache n'existe, l'erreur doit être levée explicitement.
5. **Ne jamais utiliser `withOpacity()`** : Utilisez obligatoirement la méthode moderne Flutter `.withValues(alpha: ...)`.

---

## 4. Exemple Concret de Création d'une Nouvelle Fonctionnalité

Pour ajouter un nouveau module (par exemple `messaging` pour contacter un propriétaire) :

1. **Modèle** : Définir le modèle dans `domain/models/message_model.dart` avec ses méthodes `fromJson` et `toJson`.
2. **Service distant** : Créer `data/remote/services/messaging_service.dart` pour réaliser les appels GET et POST.
3. **Repository** : Créer `data/repo/messaging_repository.dart` pour orchestrer les envois et le stockage local des conversations.
4. **Composants atomiques** : Utiliser les atomes existants (`AppTextField`, `AppButton`, `AppAvatar`) ou créer une molécule dans `presentation/components/molecules/`.
5. **Feature** : Créer le sous-dossier `presentation/features/messaging/` contenant :
   - `messaging_binding.dart`
   - `messaging_controller.dart`
   - `messaging_page.dart`
6. **Routage** : Ajouter la route dans `presentation/routes/app_routes.dart` et la déclarer dans `app_pages.dart` avec son binding.