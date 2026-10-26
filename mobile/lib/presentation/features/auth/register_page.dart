import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/models/enums.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_checkbox.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/molecules/role_segment.dart';
import '../../components/skeletons/auth_scaffold.dart';
import 'auth_controller.dart';

/// A6 · Inscription.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final AuthController controller = Get.find<AuthController>();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    controller.register(
      fullName: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.lg);
    return AuthScaffold(
      title: 'Créer un compte',
      headerHeight: 190,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => RoleSegment(
                options: const [
                  RoleOption(title: 'Locataire', subtitle: 'Je cherche un logement'),
                  RoleOption(title: 'Propriétaire', subtitle: 'Je loue mes logements'),
                ],
                selectedIndex: controller.role.value == UserRole.OWNER ? 1 : 0,
                onChanged: (i) =>
                    controller.selectRole(i == 1 ? UserRole.OWNER : UserRole.TENANT),
              ),
            ),
            gap,
            AppTextField(
              label: 'Nom complet',
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: Validators.fullName,
            ),
            gap,
            AppTextField(
              label: 'Adresse e-mail',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
            ),
            gap,
            AppTextField(
              label: 'Téléphone',
              controller: _phone,
              prefixText: '+229',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              validator: Validators.phone,
            ),
            gap,
            Obx(
              () => AppTextField(
                label: 'Mot de passe',
                controller: _password,
                obscureText: controller.hidePassword.value,
                onToggleObscure: controller.togglePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.strongPassword,
              ),
            ),
            gap,
            Obx(
              () => AppCheckbox(
                value: controller.acceptedTerms.value,
                onChanged: (v) => controller.acceptedTerms.value = v,
                label: Text(
                  'J’accepte les conditions d’utilisation de LofiSoft',
                  style: AppTextStyles.caption.copyWith(color: AppColors.ink),
                ),
              ),
            ),
            Obx(() {
              final message = controller.errorMessage.value;
              if (message == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.statusBad),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => AppButton(
                label: 'Créer mon compte',
                isLoading: controller.isLoading,
                // Désactivé tant que les conditions ne sont pas acceptées
                onPressed: controller.acceptedTerms.value ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
