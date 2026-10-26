import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/app_text_field.dart';

/// Double champ « budget minimum / maximum » en FCFA (chiffres seulement).
///
/// ```dart
/// BudgetInput(minController: _min, maxController: _max, onChanged: (_) => controller.update(...))
/// ```
/// Les deux `TextEditingController` sont créés et libérés par la page.
class BudgetInput extends StatelessWidget {
  const BudgetInput({
    super.key,
    required this.minController,
    required this.maxController,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController minController;
  final TextEditingController maxController;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final formatters = [FilteringTextInputFormatter.digitsOnly];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            label: 'Minimum',
            controller: minController,
            suffixText: AppConstants.currency,
            keyboardType: TextInputType.number,
            inputFormatters: formatters,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppTextField(
            label: 'Maximum',
            controller: maxController,
            suffixText: AppConstants.currency,
            keyboardType: TextInputType.number,
            inputFormatters: formatters,
            onChanged: onChanged,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
