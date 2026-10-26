import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_checkbox.dart';

/// Choix de l'opérateur Mobile Money (MTN Mobile Money, Moov Money).
///
/// ```dart
/// Row(children: [
///   Expanded(child: OperatorCard(name: 'MTN Mobile Money', selected: op == 'mtn', onTap: () => pick('mtn'))),
///   SizedBox(width: 12),
///   Expanded(child: OperatorCard(name: 'Moov Money', selected: op == 'moov', onTap: () => pick('moov'))),
/// ])
/// ```
class OperatorCard extends StatelessWidget {
  const OperatorCard({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.button);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.green : AppColors.line,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IgnorePointer(
                    child: AppCheckbox(value: selected, onChanged: (_) {}, round: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
