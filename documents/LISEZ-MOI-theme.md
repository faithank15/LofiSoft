# Fondations LofiSoft (core/theme) : comment s'en servir

Ces 6 fichiers vont dans `lib/core/theme/`. Tout composant et toute page les utilisent.

| Besoin | Fichier | Exemple |
|---|---|---|
| Une couleur | `app_colors.dart` | `AppColors.green` |
| Un style de texte | `app_text_styles.dart` | `Text('Salut', style: AppTextStyles.title)` |
| Une ombre | `app_shadows.dart` | `boxShadow: AppShadows.soft` |
| Un coin arrondi | `app_radius.dart` | `BorderRadius.circular(AppRadius.card)` |
| Un espace | `app_spacing.dart` | `SizedBox(height: AppSpacing.lg)` |
| Une hauteur standard | `app_spacing.dart` (AppSizes) | `height: AppSizes.button` |
| Le thème global | `app_theme.dart` | `GetMaterialApp(theme: AppTheme.light)` |

## 5 règles
1. Jamais de `Color(0xFF...)` ni `Colors.xxx` : toujours `AppColors`.
2. Jamais `withOpacity()` : utiliser `.withValues(alpha: 0.5)`.
3. Jamais de nombre magique pour un espace ou un coin : prendre dans `AppSpacing` / `AppRadius`.
4. Les statuts (Payé, Partiel, En retard) sont du TEXTE coloré, sans fond teinté.
5. L'ambre est un accent minuscule (logo, soleil), jamais un grand aplat.

## Mise en place de la police (une fois)
Mettre les .ttf de Plus Jakarta Sans (400, 600, 700, 800) dans `assets/fonts/` et déclarer dans pubspec.yaml :
```yaml
flutter:
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
        - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf
          weight: 800
```
