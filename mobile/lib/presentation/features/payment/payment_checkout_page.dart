import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/atoms/progress_bar.dart';
import '../../components/molecules/operator_card.dart';
import '../../shared/error_view.dart';
import '../../shared/loading_view.dart';
import 'payment_controller.dart';

class PaymentCheckoutPage extends StatefulWidget {
  const PaymentCheckoutPage({super.key});

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final controller = Get.find<PaymentController>();

  @override
  void initState() {
    super.initState();
    _phoneController.text = controller.defaultPhone;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int _parseAmount() {
    final clean = _amountController.text.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(clean) ?? 0;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    controller.submitPayment(
      amount: _parseAmount(),
      phone: _phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingData.value) {
            return const LoadingView();
          }

          if (controller.errorMessage.value != null &&
              controller.step.value == PaymentStep.form &&
              controller.rentalId.value.isEmpty) {
            return ErrorView(
              message: controller.errorMessage.value!,
              onRetry: controller.onInit,
            );
          }

          if (controller.step.value == PaymentStep.processing) {
            return _buildProcessingView();
          }

          if (controller.step.value == PaymentStep.failure) {
            return _buildFailureView();
          }

          return _buildFormView(context);
        }),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                color: AppColors.green,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Paiement en cours',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Veuillez confirmer l’opération sur votre téléphone en saisissant votre code secret dès l’apparition du prompt opérateur.',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureView() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFDE8E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.statusBad,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Le paiement n’a pas abouti',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              controller.errorMessage.value ??
                  'La transaction a été refusée ou a expiré.',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(label: 'Réessayer', onPressed: controller.retry),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Annuler',
              variant: AppButtonVariant.text,
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context) {
    final remaining = controller.remainingDue.value;
    final total = controller.totalDue.value;
    final paid = controller.paidSoFar.value;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // En-tête de navigation
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: AppSpacing.xs),
              Text('Payer mon loyer', style: AppTextStyles.section),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.lg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte Récapitulative du mois en cours
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Loyer en cours',
                              style: AppTextStyles.subtitle,
                            ),
                            Text(
                              'Reste ${CurrencyFormatter.format(remaining)}',
                              style: AppTextStyles.bodyStrong,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ProgressBar(value: progress),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${CurrencyFormatter.number(paid)} déjà payés sur ${CurrencyFormatter.number(total)} · ${controller.dueDateLabel.value}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section saisie du montant
                  Text(
                    'Combien voulez-vous payer ?',
                    style: AppTextStyles.section.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.green, width: 2.5),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: AppTextStyles.amount.copyWith(fontSize: 34),
                            cursorColor: AppColors.green,
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            validator: (val) {
                              final amount =
                                  int.tryParse(
                                    (val ?? '').replaceAll(RegExp(r'\D'), ''),
                                  ) ??
                                  0;
                              if (amount < 1000) {
                                return 'Minimum : 1 000 FCFA.';
                              }
                              if (amount > remaining && remaining > 0) {
                                return 'Dépasse le solde restant.';
                              }
                              return null;
                            },
                          ),
                        ),
                        Text(
                          AppConstants.currency,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.muted,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vous pouvez payer en plusieurs fois. Minimum : 1 000 FCFA par paiement.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section choix de l'opérateur
                  Text(
                    'Payer avec',
                    style: AppTextStyles.section.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: OperatorCard(
                            name: 'MTN Mobile Money',
                            selected:
                                controller.selectedOperator.value == 'MTN',
                            onTap: () => controller.selectOperator('MTN'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OperatorCard(
                            name: 'Moov Money',
                            selected:
                                controller.selectedOperator.value == 'MOOV',
                            onTap: () => controller.selectOperator('MOOV'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section numéro à débiter
                  AppTextField(
                    label: 'Numéro à débiter',
                    controller: _phoneController,
                    prefixText: AppConstants.phoneCode,
                    hintText: '01 97 12 34 56',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.phone,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Barre d'action basse fixe
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.line)),
            boxShadow: AppShadows.up,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Frais pour vous', style: AppTextStyles.subtitle),
                    Text(
                      'Aucun',
                      style: AppTextStyles.status.copyWith(
                        color: AppColors.statusOk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Payer',
                  onPressed: _submit,
                  isLoading: controller.isSubmitting.value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
