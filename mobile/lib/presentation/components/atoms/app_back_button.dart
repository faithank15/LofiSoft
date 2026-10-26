import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Flèche de retour (zone tactile de 44 x 44).
///
/// Sans `onPressed`, elle fait simplement « retour » (Navigator.maybePop), ce qui
/// fonctionne aussi avec la navigation GetX.
///
/// ```dart
/// AppBackButton()                      // flèche sombre
/// AppBackButton(color: Colors.white)   // sur un bandeau vert
/// ```
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.color = AppColors.ink});

  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.tap,
      height: AppSizes.tap,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: 'Retour',
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: color),
      ),
    );
  }
}
