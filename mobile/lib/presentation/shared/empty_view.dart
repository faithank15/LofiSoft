import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// État vide : une icône et une phrase (ex. « Aucun favori pour l'instant »).
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.label,
    this.icon = Icons.inbox_outlined,
    this.hint,
  });

  final String label;
  final String? hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: AppSpacing.lg),
            Text(label, textAlign: TextAlign.center, style: AppTextStyles.bodyStrong),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(hint!, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
            ],
          ],
        ),
      ),
    );
  }
}
