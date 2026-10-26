import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Barre de progression linéaire (loyer payé sur loyer dû). Se remplit en s'animant.
///
/// ```dart
/// ProgressBar(value: 90000 / 150000)
/// ProgressBar(value: 0.6, color: Colors.white, trackColor: Colors.white24) // sur fond sombre
/// ```
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color = AppColors.green,
    this.trackColor = AppColors.line,
  });

  /// De 0 (vide) à 1 (plein).
  final double value;
  final double height;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(target * 100).round()} %',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: target),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: trackColor)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: v,
                    child: ColoredBox(color: color, child: SizedBox(height: height)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
