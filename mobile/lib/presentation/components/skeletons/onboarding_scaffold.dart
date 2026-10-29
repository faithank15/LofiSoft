import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/screen_title.dart';
import '../molecules/bottom_cta_bar.dart';
import '../molecules/onboarding_top_nav.dart';

/// Squelette des écrans « parcours » (profil locataire, ajout d'un logement, etc.) :
/// barre haute (retour + segments + « Passer »), titre, contenu défilant,
/// bouton collé en bas.
///
/// Même grammaire visuelle que les écrans E5 → E7 : c'est le même
/// [OnboardingTopNav] et le même [BottomCtaBar] qui servent les deux parcours.
///
/// ```dart
/// OnboardingScaffold(
///   step: 1, totalSteps: 3,
///   title: 'Votre budget', subtitle: 'Pour vous montrer les bons logements.',
///   primaryLabel: 'Continuer', onPrimary: controller.next,
///   onSkip: controller.skip,
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
    required this.onSkip,
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

  /// Index de l'étape courante, en 0-based (0 = première étape).
  final int? step;

  /// Nombre total d'étapes du parcours.
  final int? totalSteps;

  /// Action de retour. Par défaut : retour GetX.
  final VoidCallback? onBack;

  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// Libellé de l'action secondaire (optionnelle).
  final String? secondaryLabel;

  /// Action de l'action secondaire.
  final VoidCallback? onSecondary;

  /// Action « Passer » : quitte le parcours sans aller au bout des étapes.
  final VoidCallback onSkip;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final currentStep = step ?? 0;
    final total = totalSteps ?? 1;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            OnboardingTopNav(
              currentStep: currentStep,
              totalSteps: total,
              onSkip: onSkip,
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.md,
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
