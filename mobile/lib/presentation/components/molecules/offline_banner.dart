import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Bandeau affiché en haut de l'écran quand il n'y a pas de connexion.
///
/// ```dart
/// OfflineBanner(lastSyncLabel: 'Informations du 22 oct. à 18 h 40')
/// ```
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.lastSyncLabel});

  /// Date des dernières informations reçues.
  final String lastSyncLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.ink,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 22, color: AppColors.surface),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pas de connexion',
                  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.surface),
                ),
                Text(
                  lastSyncLabel,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}