import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../atoms/progress_bar.dart';
import '../atoms/status_text.dart';

/// Carte du loyer du mois : montant restant à payer en grand, barre de progression, échéance.
///
/// ```dart
/// RentCard(
///   monthLabel: 'novembre',
///   remaining: 60000,
///   paid: 90000,
///   total: 150000,
///   dueLabel: 'Avant le 5 novembre',
///   statusLabel: 'Partiel',
///   statusKind: StatusKind.warn,
/// )
/// ```
class RentCard extends StatelessWidget {
  const RentCard({
    super.key,
    required this.monthLabel,
    required this.remaining,
    required this.paid,
    required this.total,
    required this.dueLabel,
    this.statusLabel,
    this.statusKind = StatusKind.neutral,
    this.header,
  });

  final String monthLabel;
  final num remaining;
  final num paid;
  final num total;
  final String dueLabel;
  final String? statusLabel;
  final StatusKind statusKind;

  /// Contenu facultatif au-dessus du montant (ex. « Bonjour Patrick »).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final soft = AppColors.mint.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.greenDeep,
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[header!, const SizedBox(height: AppSpacing.lg)],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reste à payer pour $monthLabel',
                  style: AppTextStyles.subtitle.copyWith(color: soft),
                ),
              ),
              if (statusLabel != null)
                Text(
                  statusLabel!,
                  style: AppTextStyles.status.copyWith(color: _onDark(statusKind)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: CurrencyFormatter.number(remaining),
                  style: AppTextStyles.amount.copyWith(color: AppColors.surface),
                ),
                TextSpan(
                  text: ' ${AppConstants.currency}',
                  style: AppTextStyles.section.copyWith(color: AppColors.surface),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProgressBar(
            value: total <= 0 ? 0 : paid / total,
            height: 12,
            color: AppColors.surface,
            trackColor: AppColors.surface.withValues(alpha: 0.18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${CurrencyFormatter.number(paid)} payés sur ${CurrencyFormatter.number(total)}',
                  style: AppTextStyles.caption.copyWith(color: soft, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                dueLabel,
                style: AppTextStyles.caption.copyWith(color: soft, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Version claire des couleurs de statut, lisible sur fond vert profond.
  static Color _onDark(StatusKind kind) => switch (kind) {
        StatusKind.ok => const Color(0xFFBFE8CF),
        StatusKind.warn => const Color(0xFFF6D58B),
        StatusKind.bad => const Color(0xFFF2B0A8),
        StatusKind.neutral => AppColors.mint,
      };
}
