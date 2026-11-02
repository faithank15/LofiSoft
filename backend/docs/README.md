# API LofiSoft — Documentation Backend

Le contrat d'API de référence est `documents/LofiSoft — Documentation de l'API.pdf`. L'état de l'implémentation est dans `documents/RAPPORT_IMPLEMENTATION_BACKEND.md`.

API REST Laravel consommée par l'application mobile Flutter (voir `documents/ARCHITECTURE.md` pour le côté mobile).

| Document | Contenu |
|---|---|
| `01-architecture.md` | Stack, services de production vs services locaux, structure du code |
| `02-installation-locale.md` | XAMPP (MySQL + phpMyAdmin), `.env`, migrations, seeders, comptes de test |
| `03-tests.md` | Lancer et écrire les tests (back et mobile), ce qu'ils couvrent |

## Démarrage rapide

```bash
cd backend
sudo /opt/lampp/lampp startmysql
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0
curl http://localhost:8000/api/health
```

## Légende

- **[fait]** : déjà dans le dépôt.
- **[à faire]** : prévu, pas encore codé.
- **[à confirmer]** : décision à valider par l'équipe.
