# LofiSoft — contexte pour Claude Code

Application Flutter + GetX de location de logements au Bénin (propriétaires / locataires).
Équipe de 4 : Faith, Raphaël, Cléanthe, Balbine. Chacun a un lot de pages.
Mon lot (Faith) : lot 2 « Entrée et connexion » = A5 Connexion, A6 Inscription,
B1 Rejoindre mon logement, E0 Lancement (splash).

## Règles d'architecture (voir ARCHITECTURE.md)
- GetX, organisation par fonctionnalité.
- Composants 100 % StatelessWidget, passifs, dans presentation/components (atoms, molecules, skeletons).
- Les TextEditingController vivent dans la page (StatefulWidget), jamais dans le contrôleur.
- Pas de withOpacity : utiliser .withValues(alpha:).
- Aucune couleur, taille ou rayon écrit en dur : uniquement core/theme (AppColors, AppSpacing, AppRadius, AppShadows, AppTextStyles).
- Pas de données factices dans les vrais repositories ; le faux mode passe par un FakeXService choisi dans le Binding avec AppConfig.useFakeApi.
- Pas de navigation depuis les services HTTP.
- Les identifiants sont dans le chemin de la route (/listings/details/:id).

## Lancer
flutter run --dart-define=USE_FAKE_API=true
(Le back Laravel et Cloudinary ne sont pas encore prêts.)

## Git
Ne jamais pousser (git push). Travailler en local, committer, je pousse moi-même.
Ne modifier que les fichiers de mon lot, sauf app_pages.dart / app_routes.dart / pubspec.yaml
où l'on ajoute sans rien supprimer des autres lots.