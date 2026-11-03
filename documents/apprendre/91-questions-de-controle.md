# Questions de contrôle

Répondez **à voix haute, sans regarder le code**. Notez celles où vous hésitez, relisez le chapitre concerné, puis recommencez quelques jours plus tard. Le corrigé est en bas de page ; ne le lisez qu'après avoir répondu.

## A. Vue d'ensemble

1. Citez dans l'ordre les couches traversées quand l'utilisateur touche « Se connecter », de la page jusqu'à la base.
2. Que fait `ApiClient` ? Que ne fait-il jamais ?
3. Pourquoi une couche Repository entre le contrôleur et le service ?
4. Où se trouve la vraie sécurité de l'application, et à quoi servent alors les gardes de route de l'app ?

## B. Mobile

5. Pourquoi les `TextEditingController` sont-ils dans la page et pas dans le contrôleur ?
6. Quelle différence entre `Get.lazyPut` avec et sans `fenix: true` ? Que mettre en `fenix` et pourquoi ?
7. Qu'est-ce qui déclenche le faux mode, et où le choix est-il fait ? Pourquoi pas dans le repository ?
8. Quel bug provoque `Get.find()` sans type passé à un paramètre `AuthStorage?` ?
9. Dans une page, pourquoi prendre `final profile = controller;` **avant** un `await showDialog` ?
10. Quelle est la différence entre `Get.toNamed`, `Get.offNamed` et `Get.offAllNamed` ? Lequel après une connexion réussie, et pourquoi ?
11. Que se passe-t-il, dans `ApiClient`, sur un 401 quand un jeton était envoyé ? Et sans jeton ?
12. Comment `ApiClient` traite-t-il une réponse qui est une liste JSON ?
13. Pourquoi `UserModel.fromJson` met-il des valeurs par défaut ?
14. Qu'est-ce que `LoadStatus` et comment une page l'utilise-t-elle ?
15. Pourquoi `_lookupToken` dans `JoinHousingController` ?
16. Comment `TenantRentRepository` permet-il d'afficher le loyer sans connexion ?
17. Pourquoi le contrôleur du tableau de bord propriétaire tolère-t-il l'échec du chargement des demandes ?
18. Pourquoi un bouton d'action a-t-il un « verrou » (`busy`) ?
19. Dans `AdminController`, pourquoi une carte n'est-elle retirée qu'après confirmation du serveur ?
20. Qu'est-ce qu'un `GetMiddleware` ? Que renvoie `redirect` pour laisser passer ?
21. Pourquoi `AuthMiddleware` a-t-il une priorité plus petite que `RoleMiddleware` ?
22. Pourquoi les tests utilisent-ils un `FakeServer` plutôt que les `FakeXService` ?
23. Dans les tests, pourquoi `Get.testMode = true; Get.reset();` dans `setUp` ?

## C. Backend

24. Décrivez le trajet d'une requête `POST /api/rentals/join`, du routeur à la base.
25. Que fait `role:OWNER` et que répond-il à un locataire ?
26. Pourquoi le rôle est-il vérifié **avant** la résolution du modèle de l'URL ?
27. Que fait `EnsureActiveAccount` et pourquoi répond-il 401 et non 403 ?
28. Pourquoi le login répond-il le même message pour un e-mail inconnu et un mauvais mot de passe ?
29. Quelle différence entre un logement, une annonce et une location ?
30. Dans quels cas `POST /rentals/join` répond-il 409 ? 404 ? 422 ?
31. Que devient une demande refusée par le propriétaire ? Et une location terminée ?
32. Comment le code `ABC-DEF` d'un logement est-il généré, et comment est-il garanti unique ?
33. Pourquoi `owner_id` n'est-il jamais lu dans la requête de création d'un logement ?
34. Comment une annonce est-elle empêchée de pointer vers le logement d'un autre propriétaire ?
35. Pourquoi une annonce `DRAFT` répond-elle 404 (et non 403) à un visiteur ?
36. Comment se calcule `remaining` pour une période de loyer ?
37. Décrivez les états d'un paiement en mode simulé et ce qui les fait changer.
38. À quoi sert `rent:rollover`, quand tourne-t-il, et que fait-il de l'impayé ?
39. Pourquoi `UserResource` existe-t-il, et quel bug évite-t-il ?
40. Que garantit `RefreshDatabase` dans les tests ? Qu'apporte `actingAsRole` ?

## D. Raisonner sur le code

41. Un locataire se plaint : « je vois Mon loyer vide alors que mon propriétaire a accepté ». Listez, dans l'ordre, ce que vous vérifiez.
42. Un administrateur suspend un compte. Que voit ce compte à sa prochaine action et pourquoi ?
43. Vous voulez ajouter « Retirer un favori depuis la liste ». Listez chaque fichier à toucher, mobile et backend, et les tests à écrire.
44. Vous changez le message d'une erreur 422 côté Laravel en `{ "erreur": "..." }`. Que casse-t-il côté mobile, et où ?
45. Écrivez de mémoire le squelette d'un endpoint protégé par rôle avec son test (route, contrôleur, test de succès, test de refus).

---

## Corrigé

**1.** Page (`login_page`) → `AuthController.login` → `AuthRepository.login` → `AuthService.login` → `ApiClient.post` → route `/api/auth/login` → `AuthController::login` (Laravel) → modèle `User` → base. Retour : jeton + utilisateur, enregistrés par `AuthStorage`.

**2.** Ajoute le jeton, applique le délai, convertit les erreurs réseau et HTTP en `AppException`, enveloppe une liste en `{'data': liste}`, efface la session sur un 401 avec jeton. Il ne navigue jamais.

**3.** Il combine plusieurs appels, convertit le JSON en modèles et gère le cache ; le service reste une ligne par endpoint, le contrôleur reste concentré sur l'état de l'écran.

**4.** Côté serveur (jeton Sanctum, `role:`, `EnsureActiveAccount`). Les gardes de l'app évitent d'afficher une page inutile ou interdite : du confort, contournable.

**5.** Un contrôleur GetX peut survivre à la page ; son champ garderait de la mémoire et du texte périmé. Dans le `State` de la page, il naît et meurt avec elle (`dispose()`).

**6.** Sans `fenix`, détruit avec la page ; avec `fenix`, recréé au prochain `find`. Services et repositories : on veut les retrouver sans les reconstruire à la main ; le contrôleur doit disparaître avec son écran.

**7.** La constante de compilation `AppConfig.useFakeApi` (`--dart-define=USE_FAKE_API=true`), testée dans le **binding**. Le repository ne contient jamais de faux, pour qu'aucune donnée factice ne puisse être livrée.

**8.** GetX cherche une classe nommée `AuthStorage?`, ne la trouve pas et plante au lancement de l'écran. Correctif : `Get.find<AuthStorage>()` et paramètre `required AuthStorage`.

**9.** Si l'utilisateur quitte la page pendant le dialogue, le contrôleur est détruit ; un `Get.find` après l'attente plante (« not found »). Prendre la référence avant évite cela.

**10.** Empiler / remplacer la page courante / vider toute la pile. `offAllNamed` après la connexion : on ne doit pas pouvoir revenir à l'écran de connexion avec « retour ».

**11.** Avec jeton : session expirée → `_auth.clear()` puis `UnauthorizedException` générique. Sans jeton : mauvais identifiants → `UnauthorizedException` avec le message du serveur.

**12.** Une réponse non objet est enveloppée : `{'data': liste}`. Les contrôleurs lisent alors toujours `json['data']`.

**13.** Le serveur peut omettre un champ ou envoyer `null` : sans valeur par défaut, l'application planterait sur des données imparfaites.

**14.** `initial`, `loading`, `loaded`, `failure`. Le contrôleur le range dans un `Rx` ; la page fait un `switch` dans un `Obx` pour afficher chargement, erreur (avec « réessayer ») ou contenu.

**15.** Chaque frappe complète lance une recherche ; deux réponses peuvent arriver dans le désordre. Le jeton identifie la dernière recherche et fait ignorer les réponses plus anciennes.

**16.** Après chaque chargement réussi, il sauvegarde la situation, le loyer et les paiements dans `AppStorage` ; sur `NetworkException`, il relit ce cache et marque `fromCache`.

**17.** Les demandes sont une section secondaire : si elles échouent, le tableau de bord reste utilisable. Un échec partiel ne doit pas faire tomber tout l'écran.

**18.** Pour qu'un double appui n'envoie pas deux requêtes (deux acceptations, deux suppressions).

**19.** Si la requête échoue, l'élément doit rester visible et réessayable. Retirer avant confirmation cacherait une action qui n'a pas eu lieu.

**20.** Une garde exécutée avant l'ouverture d'une route. `redirect` renvoie `null` pour laisser passer, sinon un `RouteSettings(name: ...)`.

**21.** Il faut vérifier la session avant le rôle : sans session, le rôle n'a pas de sens, et c'est la connexion qu'on veut ouvrir.

**22.** Avec `FakeServer`, on teste la vraie chaîne (conversion JSON, erreurs, URL) ; un `FakeXService` court-circuite justement ces conversions.

**23.** Chaque test repart d'un GetX vide : pas d'instance, de route ou d'état hérité d'un test précédent.

**24.** `routes/api.php` (`/rentals/join`, `auth:sanctum`, `role:TENANT`, `EnsureActiveAccount`) → `RentalController::join` : valide `code`, refuse si le locataire a déjà une location `ACTIVE`/`PENDING` (409), cherche le logement par `code` (404), refuse s'il est occupé (409), crée une `Rental` `PENDING` (201).

**25.** Il laisse passer seulement les utilisateurs du rôle OWNER ; un locataire reçoit 403 « Action réservée aux propriétaires. ».

**26.** Pour que la réponse ne révèle pas l'existence d'un identifiant (404 si inexistant, 403 si existant et interdit).

**27.** Un compte suspendu (`actif = false`) perd l'accès immédiatement, même avec un jeton valide. 401 car, pour le mobile, c'est une session invalide : il l'efface.

**28.** Ne pas révéler quelles adresses ont un compte.

**29.** Logement : le bien et son code. Annonce : sa publicité (`DRAFT`/`PUBLISHED`/`CANCELED`), créée à partir d'un logement. Location : lien locataire-logement (`PENDING`/`ACTIVE`/`FINISHED`).

**30.** 409 : le locataire a déjà une location active ou en attente, ou le logement est occupé. 404 : code inconnu. 422 : `code` absent ou non texte.

**31.** Refusée : la ligne est supprimée. Terminée : statut `FINISHED` et `ended_at` renseigné.

**32.** `Housing::generateUniqueCode` : 3 lettres majuscules aléatoires, un tiret, 3 autres ; boucle tant que le code existe ; contrainte `unique` en base en dernier recours. Généré à la création si vide.

**33.** Le serveur le pose lui-même (`$request->user()->housings()->create`) : un client ne doit pas pouvoir créer un logement au nom d'un autre.

**34.** `Rule::exists('housings', 'id')->where('owner_id', $request->user()->id)` dans la validation de `housing_id`.

**35.** Pour ne pas révéler l'existence d'un brouillon à quelqu'un qui n'y a pas droit.

**36.** `max(0, due - paid)` avec `due = total + carried_over` (ou le loyer du logement s'il n'y a pas de ligne de période) et `paid = somme des paiements SUCCESS` de la période.

**37.** `PENDING` à la création. À la première lecture après `PAYMENT_FAKE_DELAY` secondes : `SUCCESS`, ou `FAILED` si le numéro finit par `00`. Seul `SUCCESS` change le loyer et débloque le reçu.

**38.** Chaque 1er du mois à 00:05, il ouvre la période du mois pour chaque location `ACTIVE` et reporte (`carried_over`) l'impayé du mois précédent.

**39.** Une forme unique de l'utilisateur dans toutes les réponses. Il évite qu'un champ (comme `identity_verified`) soit présent dans une réponse et oublié dans une autre.

**40.** `RefreshDatabase` : une base SQLite en mémoire neuve à chaque test. `actingAsRole` : crée un utilisateur de ce rôle et le connecte via Sanctum, sans passer par le login.

**41.** Mobile : la phase renvoyée par `GET /me/situation` (logs `[api]`), le cache hors connexion (`fromCache`), tirer pour actualiser. Backend : la location est-elle `ACTIVE` (le propriétaire a-t-il vraiment accepté) ? Le logement de la demande est-il le bon ? Le locataire est-il celui de la location ?

**42.** Son jeton reste valide mais `EnsureActiveAccount` répond 401 ; `ApiClient` efface la session et lève `UnauthorizedException` ; l'utilisateur est ramené à la connexion. À la connexion suivante : 403 « Ce compte a été suspendu. ».

**43.** (Exemple de réponse attendue) Backend : route + méthode de contrôleur + test de succès et de refus. Mobile : méthode du service (+ fake), du repository, du contrôleur (verrou), bouton dans la page, test de contrôleur avec `FakeServer`.

**44.** `ApiClient._firstError` / `_message` lisent `errors` et `message` : l'application afficherait « Certaines informations sont invalides. » au lieu du vrai message. Il faut adapter `ApiClient` (et ses tests).

**45.** Route : `Route::get('/x', [XController::class, 'index'])->middleware('role:OWNER')` dans le groupe `auth:sanctum`. Test : `actingAsRole('OWNER')` → `getJson('/api/x')->assertOk()` ; `actingAsRole('TENANT')` → `assertForbidden()` ; sans connexion → `assertUnauthorized()`.
