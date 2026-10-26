import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Atome d'en-tête d'écran affichant un titre hiérarchique et un sous-titre optionnel.
///
/// Utilisé sur les écrans d'onboarding, de formulaires et de sections principales.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.isLight = false,
    this.large = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = AppSpacing.sm,
  });

  /// Libellé principal de l'écran.
  final String title;

  /// Texte explicatif ou secondaire facultatif.
  final String? subtitle;

  /// `true` : 28 px (écrans d'onboarding, accueil). `false` : 24 px.
  final bool large;

  /// Si vrai, applique des couleurs adaptées à un fond sombre (ex. vert profond #0A3D33).
  final bool isLight;

  /// Alignement horizontal des textes.
  final CrossAxisAlignment crossAxisAlignment;

  /// Espacement vertical entre le titre et le sous-titre.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final titleColor = isLight ? AppColors.surface : AppColors.ink;
    final subtitleColor = isLight ? AppColors.mint : AppColors.muted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          title,
          style: (large ? AppTextStyles.display : AppTextStyles.title)
              .copyWith(color: titleColor),
          textAlign: _resolveTextAlign(crossAxisAlignment),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          SizedBox(height: spacing),
          Text(
            subtitle!,
            style: AppTextStyles.body.copyWith(
              color: subtitleColor,
              height: 1.45,
            ),
            textAlign: _resolveTextAlign(crossAxisAlignment),
          ),
        ],
      ],
    );
  }

  TextAlign _resolveTextAlign(CrossAxisAlignment alignment) {
    return switch (alignment) {
      CrossAxisAlignment.center => TextAlign.center,
      CrossAxisAlignment.end => TextAlign.end,
      _ => TextAlign.start,
    };
  }
}
