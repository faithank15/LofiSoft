import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../atoms/app_card.dart';
import 'info_row.dart';

class ReceiptLine {
  const ReceiptLine(this.label, this.value);

  final String label;
  final String value;
}

class ReceiptSummary extends StatelessWidget {
  const ReceiptSummary({
    super.key,
    required this.amount,
    required this.lines,
    this.title = 'Paiement réussi',
  });

  final num amount;
  final List<ReceiptLine> lines;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 32,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: AppTextStyles.section),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${CurrencyFormatter.number(amount)} ${AppConstants.currency}',
                  style: AppTextStyles.amount.copyWith(fontSize: 34),
                ),
              ],
            ),
          ),
          for (var i = 0; i < lines.length; i++)
            InfoRow(
              label: lines[i].label,
              value: lines[i].value,
              showDivider: i < lines.length - 1,
            ),
        ],
      ),
    );
  }
}
