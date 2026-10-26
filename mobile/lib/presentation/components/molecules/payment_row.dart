import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../atoms/app_divider.dart';

/// Ligne d'historique : pastille de date, montant et opérateur Mobile Money.
///
/// ```dart
/// PaymentRow(date: payment.date, amount: 30000, operator: 'MTN Mobile Money')
/// PaymentRow(date: ..., amount: ..., operator: ..., isLast: true)   // dernière ligne : pas de trait
/// ```
class PaymentRow extends StatelessWidget {
  const PaymentRow({
    super.key,
    required this.date,
    required this.amount,
    required this.operator,
    this.isLast = false,
    this.onTap,
  });

  final DateTime date;
  final num amount;
  final String operator;
  final bool isLast;
  final VoidCallback? onTap;

  static const _short = ['JANV.', 'FÉVR.', 'MARS', 'AVR.', 'MAI', 'JUIN', 'JUIL.', 'AOÛT', 'SEPT.', 'OCT.', 'NOV.', 'DÉC.'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date.day.toString().padLeft(2, '0'),
                        style: AppTextStyles.section.copyWith(color: AppColors.green, height: 1.1),
                      ),
                      Text(
                        _short[date.month - 1],
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(CurrencyFormatter.format(amount), style: AppTextStyles.bodyStrong),
                      Text(operator, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const AppDivider(indent: 80),
      ],
    );
  }
}
