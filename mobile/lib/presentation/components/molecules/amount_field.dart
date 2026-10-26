import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Gros champ pour saisir le montant à payer (chiffres seulement, suffixe FCFA).
///
/// ```dart
/// AmountField(controller: _amount, onChanged: (v) => controller.setAmount(int.tryParse(v) ?? 0),
///             errorText: controller.amountError.value)
/// ```
/// Le `TextEditingController` est créé et libéré par la page.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.onChanged,
    this.errorText,
    this.hintText = '0',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String hintText;

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button + 2),
        borderSide: BorderSide(color: c, width: 2.5),
      );

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final style = AppTextStyles.amount.copyWith(fontSize: 36, letterSpacing: -0.7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button + 2),
            boxShadow: AppShadows.soft,
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: style,
            cursorColor: AppColors.green,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: hintText,
              hintStyle: style.copyWith(color: AppColors.line),
              suffixText: AppConstants.currency,
              suffixStyle: AppTextStyles.bodyStrong.copyWith(color: AppColors.muted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              enabledBorder: _border(hasError ? AppColors.statusBad : AppColors.line),
              focusedBorder: _border(hasError ? AppColors.statusBad : AppColors.green),
              border: _border(AppColors.line),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(errorText!, style: AppTextStyles.caption.copyWith(color: AppColors.statusBad)),
        ],
      ],
    );
  }
}
