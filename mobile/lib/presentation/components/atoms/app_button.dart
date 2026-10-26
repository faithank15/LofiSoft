import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Les trois styles de bouton de l'application.
enum AppButtonVariant {
  /// Plein vert avec ombre : l'action principale de l'écran (ex. « Se connecter »).
  primary,

  /// Contour vert, fond transparent : action secondaire (ex. « Partager »).
  outline,

  /// Simple texte, sans cadre : action discrète (ex. « Ce n'est pas le bon logement »).
  text,
}

/// Bouton de LofiSoft. Composant passif : il ne connaît ni GetX ni la navigation.
///
/// ```dart
/// AppButton(label: 'Se connecter', onPressed: controller.login)
/// AppButton(label: 'Créer mon compte', isLoading: controller.loading.value, onPressed: ...)
/// AppButton(label: 'Annuler', variant: AppButtonVariant.text, onPressed: ...)
/// ```
/// `onPressed: null` = bouton désactivé (grisé).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Affiche une roue de chargement à la place du texte et bloque le clic.
  final bool isLoading;

  /// `true` : prend toute la largeur. `false` : s'adapte au texte.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final isText = variant == AppButtonVariant.text;
    final height = isText ? AppSizes.buttonSmall : AppSizes.button;

    final Color background;
    final Color foreground;
    final Border? border;
    final List<BoxShadow>? shadow;

    switch (variant) {
      case AppButtonVariant.primary:
        background = enabled ? AppColors.green : AppColors.line;
        foreground = enabled ? AppColors.surface : AppColors.muted;
        border = null;
        shadow = enabled ? AppShadows.button : null;
      case AppButtonVariant.outline:
        background = Colors.transparent;
        foreground = enabled ? AppColors.green : AppColors.muted;
        border = Border.all(
          color: enabled ? AppColors.green : AppColors.line,
          width: 2,
        );
        shadow = null;
      case AppButtonVariant.text:
        background = Colors.transparent;
        foreground = enabled ? AppColors.green : AppColors.muted;
        border = null;
        shadow = null;
    }

    final content = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
          )
        : Text(
            label,
            style: AppTextStyles.button.copyWith(
              color: foreground,
              fontSize: isText ? 16 : 17,
            ),
            textAlign: TextAlign.center,
          );

    final radius = BorderRadius.circular(AppRadius.button);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Container(
        width: expanded ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: shadow,
        ),
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: border?.top ?? BorderSide.none,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Center(widthFactor: expanded ? null : 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
