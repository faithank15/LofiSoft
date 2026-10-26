import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

/// Conteneur blanc avec fine bordure et ombre légère : la base de toutes les cartes.
///
/// ```dart
/// AppCard(padding: EdgeInsets.all(16), child: Text('Bonjour'))
/// AppCard(onTap: () => ..., child: ...)      // carte cliquable
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.borderColor = AppColors.line,
    this.borderWidth = 1,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color borderColor;
  final double borderWidth;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadow ? AppShadows.soft : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
