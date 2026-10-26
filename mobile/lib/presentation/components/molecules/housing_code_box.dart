import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_button.dart';
import '../atoms/dashed_border.dart';

/// Boîte qui affiche le code unique d'un logement, avec un bouton pour le partager.
///
/// ```dart
/// HousingCodeBox(code: 'M4T-83P', onShare: () => controller.shareCode(code))
/// ```
class HousingCodeBox extends StatelessWidget {
  const HousingCodeBox({
    super.key,
    required this.code,
    required this.onShare,
    this.label = 'Code du logement',
    this.helper,
    this.shareLabel = 'Partager',
  });

  final String code;
  final VoidCallback? onShare;
  final String label;

  /// Petite phrase d'explication sous le code (facultatif).
  final String? helper;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      radius: AppRadius.card,
      background: AppColors.mint,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.greenDeep)),
                  const SizedBox(height: 2),
                  Text(
                    code,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 28,
                      letterSpacing: 2.8,
                      color: AppColors.greenDeep,
                    ),
                  ),
                  if (helper != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      helper!,
                      style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.greenDeep),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton(label: shareLabel, onPressed: onShare, expanded: false),
          ],
        ),
      ),
    );
  }
}
