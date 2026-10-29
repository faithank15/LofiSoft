import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/app_back_button.dart';
import '../atoms/screen_title.dart';
import '../atoms/step_progress_bar.dart';
import '../molecules/bottom_cta_bar.dart';

/// Squelette des écrans « parcours » (profil locataire, ajout d'un logement, etc.) :
/// retour + barre d'étapes en haut, titre, contenu défilant, bouton collé en bas.
///
/// ```dart
/// OnboardingScaffold(
///   step: 1, totalSteps: 3,
///   title: 'Votre budget', subtitle: 'Pour vous montrer les bons logements.',
///   primaryLabel: 'Continuer', onPrimary: controller.next,
///   onBack: Get.back,
///   body: BudgetInput(...),
/// )
/// ```
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.step,
    this.totalSteps,
    this.onBack,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final int? step;
  final int? totalSteps;
  final VoidCallback? onBack;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                0,
              ),
              child: Row(
                children: [
                  if (onBack != null)
                    AppBackButton(onPressed: onBack, color: AppColors.ink),
                  if (step != null && totalSteps != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StepProgressBar(
                        current: step!,
                        total: totalSteps!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xl,
                  AppSpacing.screen,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScreenTitle(title: title, subtitle: subtitle),
                    const SizedBox(height: AppSpacing.xl),
                    body,
                  ],
                ),
              ),
            ),
            BottomCtaBar(
              primaryLabel: primaryLabel,
              onPrimary: onPrimary,
              secondaryLabel: secondaryLabel,
              onSecondary: onSecondary,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
