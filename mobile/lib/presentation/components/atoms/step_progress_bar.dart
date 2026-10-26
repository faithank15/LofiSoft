import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Indicateur d'étapes : des segments dont les `current` premiers sont verts.
///
/// ```dart
/// StepProgressBar(current: 2, total: 3)   // étape 2 sur 3
/// ```
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape $current sur $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 6,
                decoration: BoxDecoration(
                  color: i < current ? AppColors.green : AppColors.line,
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
