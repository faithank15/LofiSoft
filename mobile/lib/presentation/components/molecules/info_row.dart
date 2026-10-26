import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_divider.dart';

/// Ligne « libellé à gauche, valeur à droite » (loyer, date limite, caution...).
///
/// ```dart
/// InfoRow(label: 'Caution versée', value: '700 000 FCFA')
/// InfoRow(label: 'Propriétaire', valueWidget: Text('Koffi Mensah'), showDivider: false)
/// ```
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
  });

  final String label;
  final String? value;

  /// Remplace `value` quand la valeur n'est pas un simple texte.
  final Widget? valueWidget;
  final bool showDivider;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(label, style: AppTextStyles.subtitle),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: valueWidget ??
                      Text(
                        value ?? '',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodyStrong,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const AppDivider(),
      ],
    );
  }
}
