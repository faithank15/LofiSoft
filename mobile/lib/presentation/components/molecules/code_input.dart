import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';

/// Formate la saisie du code logement : majuscules, lettres et chiffres seulement,
/// tiret automatique après 3 caractères, 6 caractères au maximum. Ex. : `K7F-29X`.
class HousingCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final cut = raw.length > 6 ? raw.substring(0, 6) : raw;
    final text = cut.length > 3 ? '${cut.substring(0, 3)}-${cut.substring(3)}' : cut;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Grand champ de saisie du code logement (écran « Rejoindre mon logement »).
/// Le tiret et les majuscules sont gérés tout seuls.
///
/// ```dart
/// CodeInput(
///   controller: _codeCtrl,               // créé et libéré par la page
///   onChanged: controller.onCodeChanged, // ex. lancer la recherche à 7 caractères
///   errorText: controller.codeError.value,
/// )
/// ```
class CodeInput extends StatelessWidget {
  const CodeInput({
    super.key,
    this.controller,
    this.onChanged,
    this.errorText,
    this.autofocus = false,
    this.hintText = 'K7F-29X',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool autofocus;
  final String hintText;

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.title.copyWith(
      fontSize: 32,
      letterSpacing: 6.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: AppShadows.soft,
          ),
          child: SizedBox(
            height: 72,
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [HousingCodeFormatter()],
              style: style,
              cursorColor: AppColors.green,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: hintText,
                hintStyle: style.copyWith(color: AppColors.line),
                contentPadding: EdgeInsets.zero,
                border: _border(AppColors.line, 1.5),
                enabledBorder: _border(
                  errorText == null ? AppColors.line : AppColors.statusBad,
                  1.5,
                ),
                focusedBorder: _border(
                  errorText == null ? AppColors.green : AppColors.statusBad,
                  2,
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.statusBad),
          ),
        ],
      ],
    );
  }
}
