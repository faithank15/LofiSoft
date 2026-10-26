import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Barre d'action basse des écrans d'onboarding (maquettes E2 → E4).
///
/// Bouton principal vert (60 px de haut, coins 18) et, si fourni, une
/// action secondaire en texte (44 px). La marge basse du téléphone est
/// gérée par le scaffold.
class OnboardingFooter extends StatelessWidget {
  /// Libellé du bouton principal.
  final String label;

  /// Action du bouton principal.
  final VoidCallback? onPressed;

  /// Libellé de l'action secondaire (optionnelle).
  final String? secondaryLabel;

  /// Action secondaire (optionnelle).
  final VoidCallback? onSecondaryPressed;

  /// Fond du bouton principal.
  final Color backgroundColor;

  /// Texte du bouton principal.
  final Color foregroundColor;

  const OnboardingFooter({
    super.key,
    required this.label,
    this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.backgroundColor = AppColors.green,
    this.foregroundColor = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: -8,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SizedBox(
              height: 60,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.button.copyWith(color: foregroundColor),
                ),
              ),
            ),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: TextButton(
                onPressed: onSecondaryPressed,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.green,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  secondaryLabel!,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
