import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

enum AppButtonVariant {
  /// Bouton vert plein avec texte blanc et ombre douce (défaut).
  primary,

  /// Bouton fond papier/blanc pour contraste sur fonds sombres (ex: E5).
  surface,

  /// Bouton avec bordure sans fond.
  outline,

  /// Bouton texte sans fond ni bordure.
  text,
}

/// Atome officiel LofiSoft de bouton d'action.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.height = AppSizes.button,
    this.width = double.infinity,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final double height;
  final double width;

  /// `false` : le bouton s'adapte à son texte au lieu de prendre toute la largeur.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onPressed != null && !isLoading;
    final effectiveWidth = expanded ? width : null;

    if (variant == AppButtonVariant.text) {
      return SizedBox(
        width: effectiveWidth,
        height: height,
        child: TextButton(
          onPressed: isInteractive ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: _buildChild(AppColors.green),
        ),
      );
    }

    final (backgroundColor, textColor, border, shadows) = switch (variant) {
      AppButtonVariant.primary => (
        isInteractive ? AppColors.green : AppColors.line,
        isInteractive ? AppColors.surface : AppColors.muted,
        null,
        isInteractive ? AppShadows.button : null,
      ),
      AppButtonVariant.surface => (
        AppColors.paper,
        AppColors.greenDeep,
        null,
        null,
      ),
      AppButtonVariant.outline => (
        Colors.transparent,
        isInteractive ? AppColors.green : AppColors.muted,
        Border.all(
          color: isInteractive ? AppColors.green : AppColors.line,
          width: 2.0,
        ),
        null,
      ),
      AppButtonVariant.text => (
        Colors.transparent,
        AppColors.green,
        null,
        null,
      ),
    };

    return Container(
      width: effectiveWidth,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          splashColor: textColor.withValues(alpha: 0.12),
          highlightColor: textColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Center(
              widthFactor: expanded ? null : 1,
              child: _buildChild(textColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    return Text(label, style: AppTextStyles.button.copyWith(color: textColor));
  }
}
