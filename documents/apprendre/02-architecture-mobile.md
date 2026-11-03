# Architecture de l'application mobile

## Le trajet d'une action

Toute action de l'utilisateur suit le même chemin, dans les deux sens. Retenez-le, tout le reste en découle.

```
Page (widget)            affiche l'état, transmet les gestes
   │  appelle
Controller (GetX)        décide : état de chargement, erreurs, navigation
   │  appelle
Repository               assemble : appelle le service, convertit le JSON en modèles, met en cache
   │  appelle
Service                  un appel HTTP = une méthode ; renvoie le JSON brut
   │  appelle
ApiClient                ajoute le jeton, applique le délai, transforme les erreurs HTTP en exceptions
   │
Serveur Laravel
```

Au retour, une erreur devient une `AppException` (`NetworkException`, `UnauthorizedException`, `ValidationException`, `ServerException`). Le contrôleur l'attrape et range son `message` dans un état observable ; la page l'affiche. Jamais d'erreur brute à l'écran.

### Pourquoi autant de couches

| Couche | Elle sait | Elle ignore |
|---|---|---|
| Page | dessiner, valider un formulaire | HTTP, JSON, navigation métier |
| Contrôleur | l'état de l'écran, où aller ensuite | la forme des URL, le JSON |
| Repository | combiner plusieurs appels, le cache | l'écran, GetX |
| Service | l'URL et les paramètres d'un endpoint | ce qu'on fait de la réponse |
| ApiClient | le jeton, les codes HTTP | les endpoints |

Chaque frontière se teste seule. Les tests du contrôleur branchent un faux serveur HTTP ; ceux du repository aussi ; aucun n'a besoin d'un écran.

## L'organisation des dossiers (`mobile/lib`)

```
main.dart, app.dart        démarrage de l'application
di/injector.dart           enregistre les singletons (stockage, client HTTP)
core/                      ce qui ne dépend de rien : thème, constantes, erreurs, utilitaires
domain/models/             les objets métier (UserModel, AnnouncementModel...) et leur lecture du JSON
data/remote/               ApiClient, services/ (vrais), fakes/ (faux)
data/repo/                 les repositories
data/cache/                AuthStorage (session), AppStorage (préférences, cache hors connexion)
presentation/
  components/              atoms, molecules, skeletons : des widgets passifs
  features/<nom>/          par fonctionnalité : binding + contrôleur + page(s)
  routes/                  noms des routes, table des pages, gardes de route
  shared/                  états communs : chargement, erreur, vide
```

Le sens des dépendances va vers le bas : `presentation` connaît `data` et `domain`, `data` connaît `domain` et `core`, `core` ne connaît personne. `di/injector.dart` est à la racine exprès : c'est le seul endroit autorisé à relier ces briques entre elles.

## GetX, ce qu'il faut vraiment savoir

GetX fait trois choses ici : l'état réactif, l'injection de dépendances, la navigation.

### 1. L'état réactif : `Rx` et `Obx`

```dart
final RxBool hidePassword = true.obs;          // une valeur observable
void togglePassword() => hidePassword.toggle(); // le contrôleur la change
Obx(() => AppTextField(obscureText: controller.hidePassword.value, ...)) // la page se redessine
```

`Obx` se redessine seulement quand une valeur `.value` lue **à l'intérieur** de sa fonction change. Piège classique : lire `.value` hors d'un `Obx`, la page ne se met alors jamais à jour.

États d'un écran qui charge : `LoadStatus { initial, loading, loaded, failure }` (dans `presentation/shared/load_status.dart`), avec un `switch` dans la page qui affiche chargement, erreur ou contenu.

### 2. L'injection : `Binding`, `lazyPut`, `find`

Un contrôleur n'est pas créé par la page, il est **fourni** par un `Binding` attaché à la route :

```dart
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(
      () => AppConfig.useFakeApi ? FakeAuthService(Get.find()) : AuthService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut<AuthController>(() => AuthController(repository: Get.find()));
  }
}
```

- `lazyPut` : créé au premier `Get.find`, pas avant.
- `fenix: true` : si l'objet est détruit, il sera recréé à la demande. Utilisé pour services et repositories, qu'on veut retrouver même après avoir quitté l'écran.
- Sans `fenix` (le contrôleur) : détruit quand la page est retirée de la pile.
- `Get.find<T>()` : va chercher l'instance enregistrée, ou plante avec « "T" not found ».

C'est ici que se joue le **faux mode** : `AppConfig.useFakeApi` (une constante de compilation, `--dart-define=USE_FAKE_API=true`) choisit `FakeAuthService` au lieu du vrai. Le repository et le contrôleur ne le savent pas : ils reçoivent un `AuthService`, vrai ou faux.

**Deux pièges que ce projet a vécus :**

- `Get.find()` sans type, passé à un paramètre `AuthStorage?` : Dart déduit le type « `AuthStorage?` », GetX cherche une classe de ce nom et plante au lancement. Règle : `required AuthStorage` et `Get.find<AuthStorage>()` explicite.
- Lire un contrôleur **après** un `await` dans une page : si l'utilisateur est parti entre-temps, le contrôleur est détruit et `Get.find` plante. Règle : prendre la référence **avant** l'attente (`final profile = controller;`). C'était le bug de la déconnexion trouvé par les robots de test.

### 3. La navigation : `Get.toNamed`, `offNamed`, `offAllNamed`

| Appel | Effet |
|---|---|
| `Get.toNamed(route)` | empile une page ; « retour » revient |
| `Get.offNamed(route)` | remplace la page courante (onglets du bas) |
| `Get.offAllNamed(route)` | vide la pile (après connexion ou déconnexion) |

Les noms de routes sont dans `AppRoutes`, jamais écrits en dur ailleurs. Les identifiants vont **dans le chemin** : `/listings/details/:id`, pas dans un argument caché.

## Les règles du projet et leur raison

| Règle | Pourquoi |
|---|---|
| Les `TextEditingController` vivent dans la page (`StatefulWidget`), libérés dans `dispose()` | Un contrôleur GetX survit à la page ; son champ de texte garderait de la mémoire et du texte périmé. |
| Composants 100 % `StatelessWidget`, passifs | Un composant reçoit ses données et ses actions en paramètres : on le réutilise et on le teste sans état caché. |
| Pas de `withOpacity`, utiliser `.withValues(alpha:)` | `withOpacity` est déprécié et perd en précision. |
| Aucune couleur, taille ou rayon en dur : `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTextStyles` | Changer la charte à un seul endroit. |
| Pas de données factices dans les vrais repositories ; le faux mode = un `FakeXService` choisi dans le binding | Le vrai code ne contient jamais de fausses données, qu'on pourrait livrer par erreur. |
| Pas de navigation depuis les services HTTP | Un service ne connaît pas l'écran. Sur 401, `ApiClient` efface la session et lève `UnauthorizedException` ; c'est au contrôleur ou à une garde de réagir. |
| Les identifiants sont dans le chemin de la route | Une page se rouvre depuis un lien ; pas d'état caché. |

## La session et les gardes

`AuthStorage` garde sur le téléphone (GetStorage) : le jeton, le rôle, le profil. `hasSession` est vrai s'il y a un jeton **et** un rôle.

Deux niveaux de protection, qui ne se remplacent pas :

1. **Côté app** (`presentation/routes/auth_middleware.dart`, `role_middleware.dart`) : sans session, on est envoyé à la connexion ; avec le mauvais rôle, on retombe sur sa propre page d'accueil. C'est du confort, pas de la sécurité : un utilisateur malveillant contourne l'app.
2. **Côté serveur** : jeton Sanctum + middleware `role:` Laravel, qui répondent 401 et 403. C'est la vraie sécurité.

## Le faux mode et les tests

- `flutter run --dart-define=USE_FAKE_API=true` : l'app tourne sans serveur. `AppPages.initial` ouvre alors le **menu de développement** (un bouton par écran).
- Les tests (`mobile/test`) n'utilisent pas les `FakeXService` : ils branchent un **vrai** `ApiClient` sur un faux serveur HTTP (`FakeServer` dans `test/support/fakes.dart`, basé sur `MockClient`). On teste ainsi les vraies conversions JSON, pas des raccourcis.
- Lancer : `cd mobile && flutter test`.

## À retenir en cinq phrases

1. Page → contrôleur → repository → service → `ApiClient` → serveur ; les erreurs remontent en `AppException`.
2. Le contrôleur porte l'état (`Rx`), la page l'affiche (`Obx`), le binding fournit les dépendances (`lazyPut`).
3. Le faux mode est un choix fait dans le binding, jamais dans le repository.
4. Les champs de texte vivent dans la page, la navigation vit dans le contrôleur.
5. La sécurité réelle est côté serveur ; les gardes de route ne sont que du confort.
