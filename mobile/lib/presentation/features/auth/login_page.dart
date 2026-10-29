import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/skeletons/auth_scaffold.dart';
import '../../routes/app_routes.dart';
import 'auth_controller.dart';

/// A5  Connexion.
/// StatefulWidget car la page possède des champs de texte : ses TextEditingController
/// sont créés ici et libérés dans dispose() (règle de l'architecture).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthController controller = Get.find<AuthController>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    controller.login(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Connexion',
      subtitle: 'Ravi de vous revoir.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Adresse e-mail',
              hintText: 'patrick.agossa@exemple.bj',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.screen),
            Obx(
              () => AppTextField(
                label: 'Mot de passe',
                hintText: '••••••••••',
                controller: _password,
                obscureText: controller.hidePassword.value,
                onToggleObscure: controller.togglePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.passwordPresent,
                onSubmitted: (_) => _submit(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'Mot de passe oublié ?',
                variant: AppButtonVariant.text,
                expanded: false,
                onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Obx(() {
              final message = controller.errorMessage.value;
              if (message == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.statusBad,
                  ),
                ),
              );
            }),
            Obx(
              () => AppButton(
                label: 'Se connecter',
                isLoading: controller.isLoading,
                onPressed: _submit,
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                Text('Pas encore de compte ?', style: AppTextStyles.subtitle),
                AppButton(
                  label: 'Créer un compte',
                  variant: AppButtonVariant.text,
                  expanded: false,
                  height: AppSizes.tap,
                  onPressed: () => Get.toNamed(AppRoutes.register),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
