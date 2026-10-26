import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../components/atoms/app_button.dart';

/// Erreur avec message et bouton « Réessayer ».
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.muted),
            const SizedBox(height: AppSpacing.lg),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'Réessayer', expanded: false, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
