# Apprendre LofiSoft pour le refaire de zéro

Objectif : être capable, pour n'importe quel fichier du projet, de dire **à quoi il sert, pourquoi il est là et ce qui casse s'il disparaît**, et de **reconstruire l'application seul**, mobile et backend, en partant d'un dossier vide.

Lire le code ne suffit pas pour y arriver. On retient ce qu'on a écrit soi-même. Ce dossier organise donc le travail en quatre temps, répétés pour chaque étape.

## Les quatre temps

1. **Lire.** Le chapitre de l'étape explique l'idée, l'ordre d'écriture des fichiers et les pièges rencontrés dans ce projet. La [carte du code](01-carte-du-code.md) donne le rôle de chaque fichier.
2. **Tracer.** Suivre une action réelle à travers le code, sans rien modifier (voir [les parcours](30-parcours-dans-le-code.md)). Exemple : toucher « Se connecter » et suivre l'appel fichier par fichier, jusqu'à la ligne PHP qui répond.
3. **Refaire.** Le script `exercice.sh` supprime les fichiers d'une étape sur une branche à part. Vous les réécrivez de mémoire ; les tests existants servent d'énoncé et de correcteur.
4. **Expliquer.** Répondre à voix haute aux [questions de contrôle](91-questions-de-controle.md) sans regarder le code. Ce qu'on ne sait pas expliquer, on ne le maîtrise pas encore.

## L'exercice « refaire », mode d'emploi

```
./documents/apprendre/exercice.sh liste                  # les étapes disponibles
./documents/apprendre/exercice.sh start    mobile-garde  # crée la branche exercice/mobile-garde, supprime les fichiers
./documents/apprendre/exercice.sh check    mobile-garde  # lance les tests : rouge au départ, vert quand c'est bon
./documents/apprendre/exercice.sh solution mobile-garde  # range VOTRE version dans .exercices/, remet l'original
./documents/apprendre/exercice.sh quitter  mobile-garde  # revient sur main
```

Règles :

- Avant `start`, tout doit être commité (le script refuse sinon). Il travaille sur la branche `exercice/<étape>`, jamais sur `main`, et ne pousse rien.
- Ouvrez le **test** avant d'écrire : il donne les noms, les paramètres et les comportements attendus. Un test qui ne compile pas vous dit quelle signature manque.
- N'ouvrez l'original qu'**après** un vrai essai. Quand vous avez fini (ou êtes bloqué), lancez `solution` puis comparez avec `diff`. Notez chaque écart : ce sont vos trous de compréhension.
- Refaites l'étape une seconde fois quelques jours plus tard. La première fois, on copie la structure ; la seconde, on la comprend.

## Ordre de travail

| Séance | Contenu | À lire | À refaire |
|---|---|---|---|
| 1 | Comment tout s'emboîte (mobile) | [02 Architecture mobile](02-architecture-mobile.md) | rien, tracer la connexion |
| 2 | Comment tout s'emboîte (backend) | [03 Architecture backend](03-architecture-backend.md) | rien, tracer `/auth/login` |
| 3 | Le socle HTTP et les erreurs | [10 Mobile](10-construire-le-mobile.md), étapes 1 à 3 | `mobile-api-client`, `mobile-user-model` |
| 4 | Navigation et gardes de route | 10, étape 4 | `mobile-garde` |
| 5 | Une fonctionnalité complète : la connexion | 10, étape 5 | `mobile-auth` |
| 6 | Base de données et modèles Laravel | [20 Backend](20-construire-le-backend.md), étapes 1 à 3 | rien, lire les migrations |
| 7 | Rôles, comptes, logements, annonces | 20, étapes 4 et 5 | `backend-roles` |
| 8 | Location : demande, acceptation, fin | 20, étape 6 | `backend-location` |
| 9 | Loyers et paiements | 20, étape 7 | `backend-solde` |
| 10 | Côté locataire : Mon loyer | 10, étape 6 | `mobile-loyer` |
| 11 | Côté propriétaire | 10, étape 7 | `mobile-demandes` |
| 12 | Administration et profil | 10, étape 8 et 20, étape 8 | `mobile-admin`, `backend-admin` |
| 13 | Les tests eux-mêmes | 10, étape 9 et 20, étape 9 | écrire un test nouveau |
| 14 | Répétition générale | [91 Questions](91-questions-de-controle.md) | tout refaire, un chapitre au choix |

Comptez deux heures par séance. Le but n'est pas la vitesse.

## Ce que vous saurez avoir réussi

- Vous dessinez de mémoire le trajet d'une action : page, contrôleur, repository, service, client HTTP, route Laravel, contrôleur Laravel, base, et le retour.
- Vous savez pourquoi les `TextEditingController` sont dans la page, pourquoi le client HTTP ne navigue jamais, pourquoi le faux mode passe par un `FakeService` choisi dans le binding.
- Vous écrivez une migration, un modèle, une route protégée par rôle et son test, sans modèle sous les yeux.
- Vous reproduisez au moins les étapes `mobile-auth`, `mobile-garde` et `backend-location` avec les tests au vert.

## Ce que ce dossier contient

| Fichier | Rôle |
|---|---|
| [01-carte-du-code.md](01-carte-du-code.md) | Chaque fichier du projet et son rôle, généré depuis les commentaires |
| [02-architecture-mobile.md](02-architecture-mobile.md) | Couches, GetX, règles du projet |
| [03-architecture-backend.md](03-architecture-backend.md) | Cycle d'une requête Laravel, rôles, contrat d'erreurs |
| [10-construire-le-mobile.md](10-construire-le-mobile.md) | Reconstruire le mobile, étape par étape |
| [20-construire-le-backend.md](20-construire-le-backend.md) | Reconstruire le backend, étape par étape |
| [30-parcours-dans-le-code.md](30-parcours-dans-le-code.md) | Les grands scénarios suivis à travers tous les fichiers |
| [90-glossaire.md](90-glossaire.md) | Les mots à connaître |
| [91-questions-de-controle.md](91-questions-de-controle.md) | Auto-évaluation |
| `exercice.sh`, `exercices.txt` | L'outil d'exercice et la liste des étapes |

## Limites honnêtes

- L'écran de paiement (B3) et le reçu (B4) n'existent pas encore ; le backend de paiement, lui, est complet. Ces deux écrans sont un bon premier exercice de création, une fois le reste maîtrisé.
- **L'application ne permet pas de signaler une annonce** : `report_service.dart` et `report_repository.dart` sont vides, aucun écran n'envoie de signalement. Le backend est prêt. Les signalements que voit l'administrateur viennent donc de l'API directement.
- **17 fichiers du squelette initial sont vides** (paiement, signalement, quelques modèles, `login_controller.dart`, `register_controller.dart`, `app_logger.dart`, `tenant_onboarding_page.dart`). La [carte du code](01-carte-du-code.md) les marque. Ils ne sont pas cassés : ils n'ont jamais été écrits.
- Les exercices couvrent les morceaux les plus formateurs, pas chaque fichier. Pour les autres (les composants visuels, les écrans d'onboarding), la méthode est la même : lire le test ou la maquette, réécrire, comparer.
