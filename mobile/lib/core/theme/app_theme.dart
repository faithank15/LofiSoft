import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Assemblage du thème Material 3 de l'application.
///
/// À brancher UNE fois dans `app.dart` :
///   GetMaterialApp(theme: AppTheme.light, ...)
///
/// Les composants utilisent d'abord AppColors / AppTextStyles directement.
/// Ce thème sert de filet de sécurité : les widgets Material standards
/// (Scaffold, AppBar, TextField, SnackBar...) auront déjà les bonnes couleurs.
abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.green,
      onPrimary: AppColors.surface,
      secondary: AppColors.amber,
      onSecondary: AppColors.ink,
      error: AppColors.statusBad,
      onError: AppColors.surface,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      outline: AppColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: AppColors.paper,
      dividerColor: AppColors.line,
      textTheme: TextTheme(
        headlineMedium: AppTextStyles.display,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.section,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.subtitle,
        labelLarge: AppTextStyles.button,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.section,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.statusBad, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Pas de mode sombre dans les maquettes pour l'instant : on renvoie le clair.
  /// À remplacer si l'équipe décide d'en faire un.
  /// static ThemeData get dark => light;
}
