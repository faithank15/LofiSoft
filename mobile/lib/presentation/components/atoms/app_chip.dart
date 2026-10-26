import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Choix sélectionnable en forme de pilule (type de logement, nombre de pièces, filtres).
///
/// ```dart
/// Obx(() => AppChip(
///   label: 'Appartement',
///   selected: controller.types.contains('apartment'),
///   onTap: () => controller.toggleType('apartment'),
/// ))
/// ```
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.chip);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: AppSizes.tap,
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.surface,
          borderRadius: radius,
          border: selected ? null : Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.surface : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
