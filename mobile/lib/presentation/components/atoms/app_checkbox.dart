import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Case à cocher de LofiSoft : carré arrondi (ou rond avec `round: true`).
///
/// ```dart
/// Obx(() => AppCheckbox(
///   value: controller.acceptedTerms.value,
///   onChanged: (v) => controller.acceptedTerms.value = v,
///   label: const Text('J’accepte les conditions d’utilisation'),
/// ))
/// ```
/// Sans `label`, c'est juste la case (utile dans une carte de choix).
/// `onChanged: null` = case désactivée.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.round = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Widget affiché à droite de la case (généralement un `Text`).
  final Widget? label;

  /// `true` : case ronde (sélection dans une carte). `false` : carrée.
  final bool round;

  @override
  Widget build(BuildContext context) {
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: value ? AppColors.green : AppColors.surface,
        borderRadius: BorderRadius.circular(round ? 12 : 7),
        border: Border.all(
          color: value ? AppColors.green : AppColors.muted,
          width: 1.5,
        ),
      ),
      child: value
          ? const Icon(Icons.check_rounded, size: 17, color: AppColors.surface)
          : null,
    );

    return Semantics(
      checked: value,
      enabled: onChanged != null,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tap, minWidth: AppSizes.tap),
          child: Row(
            mainAxisSize: label == null ? MainAxisSize.min : MainAxisSize.max,
            children: [
              box,
              if (label != null) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(child: label!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
