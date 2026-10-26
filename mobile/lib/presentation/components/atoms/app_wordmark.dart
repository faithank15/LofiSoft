import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Nom de la marque : « Lofi » + « Soft » (deux couleurs).
///
/// ```dart
/// AppWordmark()                                   // sur fond clair
/// AppWordmark(size: 42, onDark: true)             // sur fond vert profond
/// ```
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.size = 20, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -size * 0.03,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Lofi',
            style: base.copyWith(color: onDark ? AppColors.surface : AppColors.ink),
          ),
          TextSpan(
            text: 'Soft',
            style: base.copyWith(
              color: onDark ? const Color(0xFF8FD3B4) : AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}
