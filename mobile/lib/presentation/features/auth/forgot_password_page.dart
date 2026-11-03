import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/skeletons/auth_scaffold.dart';
import 'forgot_password_controller.dart';

/// Mot de passe oublié : on saisit son e-mail, le serveur envoie un lien.
/// StatefulWidget : le TextEditingController vit dans la page, pas dans le contrôleur.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final ForgotPasswordController controller = Get.find<ForgotPasswordController>();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    controller.send(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Mot de passe oublié',
      subtitle: 'Nous vous envoyons un lien pour en choisir un nouveau.',
      child: Obx(() {
        if (controller.sent.value) return _sent();
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Adresse e-mail',
                hintText: 'patrick.agossa@exemple.bj',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.screen),
              if (controller.errorMessage.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    controller.errorMessage.value!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: AppColors.statusBad),
                  ),
                ),
              AppButton(
                label: 'Envoyer le lien',
                isLoading: controller.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _sent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Si cette adresse correspond à un compte, un lien de réinitialisation vient d’y être envoyé.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.screen),
        AppButton(label: 'Retour à la connexion', onPressed: Get.back),
      ],
    );
  }
}
