import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// En-tête commun des étapes d'onboarding (E2 → E4).
///
/// Reprend la maquette à la lettre :
/// - fond clair (beige), pas de bandeau vert foncé ;
/// - flèche de retour à l'encre ;
/// - trois barres de progression de **largeur égale** (6 px de haut) ;
/// - action « Passer » en gris.
///
/// Le nombre de barres actives est déduit de [step] : 1 barre à E2,
/// 2 barres à E3, 3 barres à E4.
class OnboardingStepHeader extends StatelessWidget {
  /// Étape courante, à partir de 1.
  final int step;

  /// Nombre total d'étapes de la progression.
  final int totalSteps;

  /// Action de retour. Par défaut : retour arrière dans la pile.
  final VoidCallback? onBack;

  /// Action « Passer ».
  final VoidCallback? onSkip;

  /// Fond de l'en-tête.
  final Color backgroundColor;

  /// Couleur de la flèche de retour.
  final Color foregroundColor;

  /// Couleur du libellé « Passer ».
  final Color skipColor;

  /// Couleur d'une barre déjà franchie.
  final Color activeColor;

  /// Couleur d'une barre restante.
  final Color inactiveColor;

  const OnboardingStepHeader({
    super.key,
    required this.step,
    this.totalSteps = 3,
    this.onBack,
    this.onSkip,
    this.backgroundColor = AppColors.paper,
    this.foregroundColor = AppColors.ink,
    this.skipColor = AppColors.muted,
    this.activeColor = AppColors.green,
    this.inactiveColor = AppColors.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Retour (44 × 44 comme sur la maquette)
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back, size: 24, color: foregroundColor),
              padding: EdgeInsets.zero,
              splashRadius: 22,
              tooltip: 'Retour',
            ),
          ),
          // Progression : barres de largeur égale
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: List.generate(totalSteps, (i) {
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: i < step ? activeColor : inactiveColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Passer
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: skipColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text(
                'Passer',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
