import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Conteneur blanc standard LofiSoft avec bordure fine et ombre portée douce.
///
/// Conforme aux spécifications du Design System :
/// - Fond : [AppColors.surface]
/// - Bordure : [AppColors.line]
/// - Rayon : [AppRadius.card]
/// - Ombre : [AppShadows.soft]
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius? borderRadius;
  final bool showShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.line,
    this.borderRadius,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppRadius.card);

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveRadius,
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: showShadow ? AppShadows.soft : null,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: AppColors.green.withValues(alpha: 0.08),
          highlightColor: AppColors.green.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return content;
  }
}
