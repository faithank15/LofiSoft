import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_back_button.dart';
import '../atoms/step_progress_bar.dart';

/// Barre haute commune aux écrans d'onboarding.
///
/// Référence de design : les écrans E5 → E7 (onboarding propriétaire).
/// De gauche à droite : bouton de retour, segments d'avancement, action
/// « Passer ».
///
/// ```dart
/// OnboardingTopNav(
///   currentStep: 1,   // 0-based : 0 = première étape
///   totalSteps: 3,
///   onSkip: controller.skip,
/// )
/// ```
class OnboardingTopNav extends StatelessWidget {
  const OnboardingTopNav({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onSkip,
    this.onBack,
    this.isLight = false,
  });

  /// Index de l'étape courante, en 0-based (0 = première étape).
  final int currentStep;

  /// Nombre total d'étapes du parcours.
  final int totalSteps;

  /// Action « Passer » : quitte le parcours sans aller au bout des étapes.
  final VoidCallback onSkip;

  /// Action de retour. Par défaut : retour GetX.
  final VoidCallback? onBack;

  /// `true` : le fond est vert foncé, les éléments passent en clair (E5).
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final skipColor = isLight ? AppColors.mint : AppColors.muted;
    final activeSegment = isLight ? AppColors.surface : AppColors.green;
    final inactiveSegment = isLight
        ? AppColors.surface.withValues(alpha: 0.25)
        : AppColors.line;

    return Container(
      height: AppSizes.appBar,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          AppBackButton(isLight: isLight, onPressed: onBack),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: StepProgressBar(
                current: currentStep + 1,
                total: totalSteps,
                activeColor: activeSegment,
                inactiveColor: inactiveSegment,
                gap: AppSpacing.xs,
              ),
            ),
          ),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Passer',
              style: AppTextStyles.label.copyWith(
                color: skipColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
