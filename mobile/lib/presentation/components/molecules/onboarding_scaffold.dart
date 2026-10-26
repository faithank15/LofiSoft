import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'onboarding_step_header.dart';

/// Ossature commune des écrans d'onboarding E2 → E4.
///
/// Rendu mobile correct :
/// - l'en-tête d'étapes reste hors de la zone scrollable ;
/// - le contenu défile si l'écran est petit (aucun débordement) ;
/// - la barre d'action basse reste visible et tient compte de la barre
///   d'accueil du téléphone (encoche / gestes).
class OnboardingScaffold extends StatelessWidget {
  /// Étape courante, à partir de 1.
  final int step;

  /// Nombre total d'étapes de la progression.
  final int totalSteps;

  /// Contenu scrollable de l'écran.
  final Widget body;

  /// Barre d'action basse (bouton principal et action secondaire).
  final Widget? footer;

  /// Action de retour de l'en-tête.
  final VoidCallback? onBack;

  /// Action « Passer » de l'en-tête.
  final VoidCallback? onSkip;

  /// Fond de l'écran.
  final Color backgroundColor;

  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.body,
    this.totalSteps = 3,
    this.footer,
    this.onBack,
    this.onSkip,
    this.backgroundColor = AppColors.paper,
  });

  @override
  Widget build(BuildContext context) {
    // Marge basse réelle du téléphone (barre d'accueil / gestes).
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            OnboardingStepHeader(
              step: step,
              totalSteps: totalSteps,
              onBack: onBack,
              onSkip: onSkip,
              backgroundColor: backgroundColor,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: body,
              ),
            ),
            if (footer != null)
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}
