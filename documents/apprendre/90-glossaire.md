# Glossaire

## Flutter et Dart

| Mot | Sens |
|---|---|
| Widget | Un élément d'interface (bouton, texte, page). Tout est widget. |
| `StatelessWidget` | Widget sans état propre : même entrée, même rendu. Tous les composants du projet. |
| `StatefulWidget` | Widget avec un état qui change (ici : les pages qui ont des champs de texte). |
| `TextEditingController` | Objet qui lit et écrit le texte d'un champ. À libérer dans `dispose()`. |
| `Future` / `async` / `await` | Valeur qui arrive plus tard (réponse réseau). `await` attend sans bloquer l'interface. |
| `sealed class` | Classe dont on connaît toutes les sous-classes ; le compilateur vérifie les `switch`. |
| `const` | Valeur fixée à la compilation. `AppConfig.useFakeApi` en est une. |
| `--dart-define` | Passe une valeur au compilateur (`USE_FAKE_API=true`). |
| `fromJson` / `toJson` | Convertir un objet depuis / vers du JSON. |
| `null-aware` (`?value`, `??`) | Ignorer ou remplacer une valeur nulle. `'role': ?role` n'ajoute la clé que si `role` n'est pas nul. |

## GetX

| Mot | Sens |
|---|---|
| `GetxController` | Classe qui porte l'état d'un écran et sa logique. |
| `Rx`, `.obs` | Valeur observable : `final RxBool open = false.obs;` |
| `Obx` | Widget qui se redessine quand une valeur `.value` lue dedans change. |
| `Bindings` | Classe qui enregistre les dépendances d'une route. |
| `Get.put` | Enregistre tout de suite. `permanent: true` : jamais détruit. |
| `Get.lazyPut` | Enregistre une fabrique : l'objet naît au premier `find`. |
| `fenix: true` | Recréé automatiquement s'il a été détruit. |
| `Get.find<T>()` | Récupère l'instance enregistrée. Plante si absente. |
| `GetMiddleware` | Garde de route : `redirect(route)` renvoie `null` (passer) ou une autre route. |
| `Get.toNamed` / `offNamed` / `offAllNamed` | Empiler / remplacer / vider la pile et aller à. |
| `Get.testMode` | Mode de test de GetX (à activer dans les tests). |

## Architecture du projet

| Mot | Sens |
|---|---|
| Atome / molécule / squelette | Niveaux de composants : petit élément (bouton), assemblage (carte d'action), structure de page. |
| Service | Une méthode par appel HTTP, renvoie du JSON brut. |
| Repository | Assemble les services, convertit en modèles, gère le cache. |
| Modèle (domaine) | Objet métier lu depuis le JSON (`UserModel`...). |
| Fake (`FakeAuthService`) | Service simulé, choisi dans le binding quand `useFakeApi` est vrai. |
| `FakeServer` (tests) | Faux serveur HTTP : un vrai `ApiClient` est branché dessus. |
| `LoadStatus` | `initial`, `loading`, `loaded`, `failure` : l'état d'un écran qui charge. |
| Session | Jeton + rôle + profil, gardés par `AuthStorage`. |
| Garde de route | Confort d'interface (session, rôle). La sécurité réelle est côté serveur. |

## Laravel et API

| Mot | Sens |
|---|---|
| Route | Association URL + verbe HTTP → contrôleur (`routes/api.php`). |
| Contrôleur | Classe dont chaque méthode répond à une route. |
| Middleware | Code exécuté avant le contrôleur (jeton, rôle, compte actif). |
| Eloquent / modèle | L'accès à la base par des classes (`Housing::where(...)`). |
| Migration | Fichier qui crée ou modifie une table. L'ensemble des migrations est le schéma. |
| Seeder | Remplit la base avec des données de démonstration. |
| Resource | Classe qui fixe la forme du JSON d'un modèle. |
| Cast | Conversion automatique d'un champ (`role` → énumération `UserRole`). |
| `fillable` | Champs qu'on a le droit de remplir en masse (protège contre l'injection de champs). |
| Sanctum | Système de jetons d'API : `createToken`, `auth:sanctum`. |
| UUID | Identifiant aléatoire (`01a19c7a-...`) au lieu d'un entier. |
| Énumération (`Enum`) | Liste fermée de valeurs (`PENDING`, `ACTIVE`...). |
| Commande artisan | `php artisan <nom>` : migrer, tester, lancer une tâche (`rent:rollover`). |
| Webhook | Appel envoyé par un service externe (l'opérateur de paiement) vers votre serveur. |

## Codes HTTP utilisés

| Code | Sens ici |
|---|---|
| 200, 201, 204 | succès, création, succès sans contenu (logout) |
| 400 | requête refusée (reçu d'un paiement non abouti) |
| 401 | non authentifié ou compte suspendu |
| 403 | authentifié mais pas le droit |
| 404 | introuvable |
| 409 | conflit avec l'état actuel (déjà une location) |
| 422 | données invalides |
| 502 | service externe en échec (Cloudinary) |

## Métier

| Mot | Sens |
|---|---|
| Logement | Le bien : loyer, jour d'échéance, ville, **code d'adhésion**. |
| Annonce | La publicité d'un logement : `DRAFT`, `PUBLISHED`, `CANCELED`. |
| Location (`rental`) | Le lien locataire-logement : `PENDING`, `ACTIVE`, `FINISHED`. |
| Code d'adhésion | `ABC-DEF`, donné par le propriétaire au locataire. |
| Période | Un mois de loyer (`AAAA-MM`) avec son total et le report d'impayé. |
| Report (`carried_over`) | L'impayé du mois précédent ajouté au mois courant. |
| Badge « Vérifié » | Un propriétaire dont l'identité a été validée (`identity_verified`). |
