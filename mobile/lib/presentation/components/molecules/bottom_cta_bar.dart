import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';

/// Barre fixe en bas d'écran : bouton principal et, en dessous, un lien secondaire.
///
/// ```dart
/// BottomCtaBar(
///   primaryLabel: 'Continuer',
///   onPrimary: controller.next,
///   secondaryLabel: 'Passer',
///   onSecondary: controller.skip,
/// )
/// ```
/// À placer dans `Scaffold.bottomNavigationBar` (le squelette d'onboarding le fait).
class BottomCtaBar extends StatelessWidget {
  const BottomCtaBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.up,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(label: primaryLabel, onPressed: onPrimary, isLoading: isLoading),
              if (secondaryLabel != null)
                AppButton(
                  label: secondaryLabel!,
                  onPressed: onSecondary,
                  variant: AppButtonVariant.text,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
