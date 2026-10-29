import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Indicateur d'étapes : des segments dont les `current` premiers sont colorés.
///
/// ```dart
/// StepProgressBar(current: 2, total: 3)   // étape 2 sur 3
/// ```
///
/// Les couleurs et l'écart sont paramétrables pour que le même atome serve
/// sur fond clair (onboarding locataire) comme sur fond vert foncé (E5).
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.activeColor = AppColors.green,
    this.inactiveColor = AppColors.line,
    this.gap = 6,
  });

  /// Numéro de l'étape courante, en 1-based (1 = première étape).
  final int current;

  /// Nombre total d'étapes du parcours.
  final int total;

  /// Couleur des segments déjà parcourus.
  final Color activeColor;

  /// Couleur des segments restants.
  final Color inactiveColor;

  /// Espace horizontal entre deux segments.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape $current sur $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 6,
                decoration: BoxDecoration(
                  color: i < current ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
