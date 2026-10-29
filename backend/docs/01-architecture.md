# Architecture du backend

## 1. Stack

- Laravel (PHP 8.2+), API JSON uniquement, préfixe `/api`.
- Authentification : Laravel Sanctum, jetons personnels (`Authorization: Bearer <token>`). [fait : package et migration `personal_access_tokens`]
- Base de données : MySQL.
- Identifiants des tables métier : UUID (comme dans le diagramme de classes).

---

## 2. Services : production et local

Le code ne dépend que de la configuration `.env`. Passer du local à la production ne change aucune ligne de code.

| Besoin | Production | Local (tests) |
|---|---|---|
| Hébergement de l'API | Render | `php artisan serve` |
| Base de données | À préciser [à confirmer] | MySQL de XAMPP |
| Administration de la base | — | phpMyAdmin de XAMPP |
| Photos des annonces | Cloudinary | Disque local (`storage/app/public`) |
| Paiement Mobile Money (MTN / Moov) | KKiaPay | Faux paiement (voir §3) |
| E-mails (mot de passe oublié) | À préciser [à confirmer] | Pilote `log` (le mail s'écrit dans `storage/logs`) |

### Règle d'abstraction

Pour les photos et les paiements, le contrôleur n'appelle jamais Cloudinary ou KKiaPay directement. Il appelle une interface, et le choix de l'implémentation se fait dans un `ServiceProvider` selon le `.env`. C'est la même idée que `FakeXService` + `AppConfig.useFakeApi` côté mobile.

```
PhotoStorage      -> CloudinaryPhotoStorage | LocalPhotoStorage
PaymentGateway    -> KkiapayGateway         | FakePaymentGateway
```

---

## 3. Variables d'environnement propres au projet

```env
PHOTO_DRIVER=local          # local | cloudinary
PAYMENT_DRIVER=fake         # fake | kkiapay

CLOUDINARY_URL=
KKIAPAY_PUBLIC_KEY=
KKIAPAY_PRIVATE_KEY=
KKIAPAY_SECRET=
```

Aucune clé réelle dans le dépôt : seul `.env.example` est versionné, avec des valeurs vides.

---

## 4. Structure du code (cible)

```
app/
  Enums/                 UserRole, RentalStatus, AnnouncementStatus, AccommodationType, ReportStatus
  Models/                un modèle Eloquent par table
  Http/
    Controllers/Api/     un contrôleur par ressource, fin : il délègue
    Requests/            validation (FormRequest), une classe par action
    Resources/           format JSON de sortie (JsonResource)
    Middleware/          EnsureRole (TENANT / OWNER / ADMIN)
  Services/              logique métier (paiement, génération de reçu, code logement)
  Contracts/             PhotoStorage, PaymentGateway
routes/api.php
```

Règles :
1. Validation dans les `FormRequest`, jamais dans le contrôleur.
2. Sortie JSON uniquement via les `Resource`, pour ne jamais exposer `password` ou une colonne interne.
3. Les droits (« cette annonce est-elle à moi ? ») sont vérifiés par des Policies.
4. Les rôles protègent les routes par middleware.
