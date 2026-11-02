import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Champ de saisie de LofiSoft : libellé au-dessus, cadre blanc, bordure verte au focus.
///
/// RÈGLE DE L'ARCHITECTURE : le `TextEditingController` n'est PAS créé ici, ni dans le
/// GetxController. La page (StatefulWidget) le crée, le passe en paramètre et le libère
/// dans son `dispose()`.
///
/// ```dart
/// AppTextField(
///   label: 'Adresse e-mail',
///   controller: _emailCtrl,
///   keyboardType: TextInputType.emailAddress,
///   validator: Validators.email,
/// )
///
/// // Mot de passe avec l'œil : l'état "visible ou non" vit dans le contrôleur GetX
/// Obx(() => AppTextField(
///   label: 'Mot de passe',
///   controller: _pwdCtrl,
///   obscureText: controller.hidePassword.value,
///   onToggleObscure: controller.togglePassword,
/// ))
///
/// // Téléphone avec préfixe
/// AppTextField(label: 'Téléphone', prefixText: '+229', controller: _phoneCtrl)
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.hintText,
    this.prefixText,
    this.suffixText,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
  });

  /// Nombre de lignes maximum (1 par défaut ; `null` = illimité, pour une description).
  final int? maxLines;
  final int? minLines;

  /// Libellé affiché au-dessus du champ.
  final String? label;
  final TextEditingController? controller;
  final String? hintText;

  /// Texte fixe à gauche (ex. « +229 »).
  final String? prefixText;

  /// Texte fixe à droite (ex. « FCFA »).
  final String? suffixText;

  /// Masque la saisie (mot de passe).
  final bool obscureText;

  /// Si fourni, affiche l'œil et l'appelle au clic. C'est à l'appelant de
  /// changer `obscureText` (via une variable observable GetX).
  final VoidCallback? onToggleObscure;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Validation (utiliser les fonctions de `core/utils/validators.dart`).
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Message d'erreur imposé de l'extérieur (ex. erreur renvoyée par le serveur).
  final String? errorText;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _fixed(String text, {required bool left}) => Padding(
        padding: EdgeInsets.only(left: left ? AppSpacing.lg : 0, right: left ? AppSpacing.sm : AppSpacing.lg),
        child: Center(
          widthFactor: 1,
          child: Text(
            text,
            style: left
                ? AppTextStyles.bodyStrong.copyWith(color: AppColors.muted)
                : AppTextStyles.subtitle,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    Widget? suffix;
    if (onToggleObscure != null) {
      suffix = IconButton(
        onPressed: onToggleObscure,
        tooltip: obscureText ? 'Afficher' : 'Masquer',
        icon: Icon(
          obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.muted,
          size: 22,
        ),
      );
    } else if (suffixText != null) {
      suffix = _fixed(suffixText!, left: false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.label),
          const SizedBox(height: 7),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          minLines: obscureText ? null : minLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          cursorColor: AppColors.green,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            hintText: hintText,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
            errorText: errorText,
            errorStyle: AppTextStyles.caption.copyWith(color: AppColors.statusBad),
            contentPadding: EdgeInsets.fromLTRB(
              prefixText == null ? AppSpacing.lg : 0,
              15,
              AppSpacing.lg,
              15,
            ),
            prefixIcon: prefixText == null ? null : _fixed(prefixText!, left: true),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            border: _border(AppColors.line, 1.5),
            enabledBorder: _border(AppColors.line, 1.5),
            disabledBorder: _border(AppColors.line, 1.5),
            focusedBorder: _border(AppColors.green, 2),
            errorBorder: _border(AppColors.statusBad, 1.5),
            focusedErrorBorder: _border(AppColors.statusBad, 2),
          ),
        ),
      ],
    );
  }
}
