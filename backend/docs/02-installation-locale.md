# Installation locale

Prérequis : PHP 8.2+, Composer, XAMPP (MySQL et phpMyAdmin).

---

## 1. Base de données (XAMPP)

```bash
sudo /opt/lampp/lampp startmysql
```

phpMyAdmin : http://localhost/phpmyadmin (utilisateur `root`, sans mot de passe). Créer la base `lofisoft` (interclassement `utf8mb4_unicode_ci`), ou :

```bash
/opt/lampp/bin/mysql -uroot -e "CREATE DATABASE IF NOT EXISTS lofisoft CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
```

---

## 2. Lancement

```bash
cd backend
composer install
cp .env.example .env        # DB_* déjà réglés pour XAMPP
php artisan key:generate
php artisan migrate:fresh --seed
php artisan storage:link
php artisan serve --host=0.0.0.0
```

Test : `curl http://localhost:8000/api/health`

`migrate:fresh --seed` efface toute la base et la remplit avec les données de démonstration.

---

## 3. Comptes de démonstration

Mot de passe de tous les comptes : `Test1234`.

| E-mail | Rôle | Particularité |
|---|---|---|
| locataire@lofi.bj | TENANT | Location active, loyer du mois payé 90 000 sur 150 000, 2 favoris |
| locataire2@lofi.bj | TENANT | Sans location : pour tester « Rejoindre mon logement » |
| proprio@lofi.bj | OWNER | Vérifié, 2 logements, 5 annonces |
| proprio2@lofi.bj | OWNER | Non vérifié, demande d'identité en attente |
| admin@lofi.bj | ADMIN | Un signalement en attente |

Codes logement : `M4T-83P` (loué à locataire@lofi.bj), `K7F-29X` et `P9Q-55D` (libres).

---

## 4. Brancher l'application mobile

| Cible | Adresse de l'API |
|---|---|
| Émulateur Android | `http://10.0.2.2:8000/api` (valeur par défaut de `AppConfig`) |
| Téléphone réel (même Wi-Fi) | `http://<IP du PC>:8000/api` |

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
```

Sans `USE_FAKE_API`, l'app parle au vrai serveur.

---

## 5. Problèmes fréquents

| Symptôme | Cause probable |
|---|---|
| `Connection refused` à la migration | MySQL de XAMPP non démarré |
| `could not find driver` | Extension PHP `pdo_mysql` absente |
| L'app mobile n'atteint pas l'API | `serve` lancé sans `--host=0.0.0.0`, ou pare-feu sur le port 8000 |

## Services optionnels

Sans configuration, tout fonctionne en local. Les messages de validation sont en français (`lang/fr`, `APP_LOCALE=fr`).

| Variable `.env` | Effet |
|---|---|
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Si les trois sont renseignées, `POST /api/uploads` envoie les images vers Cloudinary (dossier `lofisoft/<kind>`). Sinon elles vont dans `storage/app/public` (penser à `php artisan storage:link`). |
| `PAYMENT_DRIVER` | `fake` (défaut) : paiement simulé. `POST /payments` crée un paiement `PENDING` ; `GET /payments/{id}` le passe à `SUCCESS` après `PAYMENT_FAKE_DELAY` secondes (4 par défaut), ou `FAILED` si le numéro finit par `00`. `kkiapay` : seul le webhook conclut le paiement. |
| `KKIAPAY_SECRET` | Si renseignée, `POST /api/payments/webhook` exige l'en-tête `x-kkiapay-secret` identique, sinon 401. Vide en local : le webhook est accepté ; en production il est refusé (503). |

## Rôles

Le middleware `role:OWNER|TENANT|ADMIN` (`EnsureRole`) protège les routes : espace propriétaire, annonces/logements (OWNER), rejoindre un logement et payer (TENANT), `/admin/*` (ADMIN). Mauvais rôle : 403 `{ "message": ... }`.

## Passage mensuel des loyers

```bash
php artisan rent:rollover                  # mois courant
php artisan rent:rollover --month=2026-11  # mois précis
```

Pour chaque location active, ouvre la période du mois (loyer du logement) et reporte l'impayé du mois précédent dans `carried_over`. Idempotent. Planifiée le 1er de chaque mois à 00:05 : en production, ajouter au cron `* * * * * php artisan schedule:run`.
