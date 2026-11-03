import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/models/enums.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/atoms/progress_bar.dart';
import '../../components/molecules/amount_field.dart';
import '../../components/molecules/operator_card.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'payment_controller.dart';

/// B3 "Payer mon loyer" (lot 6) : montant, opérateur, numéro à débiter, bouton "Payer".
class PaymentCheckoutPage extends StatefulWidget {
  const PaymentCheckoutPage({super.key});

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  // REGLE : les TextEditingController vivent dans la page, jamais dans le controleur.
  late final TextEditingController _amountCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentController>();
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Obx(() {
          final loaded = controller.loadStatus.value == LoadStatus.loaded;
          return Column(
            children: [
              // En-tete 60 px : retour + titre.
              SizedBox(
                height: AppSizes.appBar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    children: [
                      const AppBackButton(),
                      Expanded(
                        child: Text('Payer mon loyer', style: AppTextStyles.section),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: switch (controller.loadStatus.value) {
                  LoadStatus.initial || LoadStatus.loading => const LoadingView(),
                  LoadStatus.failure => ErrorView(
                      message: controller.errorMessage.value ?? 'Chargement impossible.',
                      onRetry: controller.load,
                    ),
                  LoadStatus.loaded => _Form(
                      controller: controller,
                      amountCtrl: _amountCtrl,
                      phoneCtrl: _phoneCtrl,
                    ),
                },
              ),
              if (loaded) _BottomBar(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.controller,
    required this.amountCtrl,
    required this.phoneCtrl,
  });

  final PaymentController controller;
  final TextEditingController amountCtrl;
  final TextEditingController phoneCtrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 6, AppSpacing.screen, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Carte "loyer du mois" : reste a payer et progression.
          AppCard(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(controller.rentCardTitle, style: AppTextStyles.subtitle),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(controller.rentCardRemaining, style: AppTextStyles.bodyStrong),
                  ],
                ),
                const SizedBox(height: 10),
                ProgressBar(value: controller.progressValue),
                const SizedBox(height: 10),
                Text(controller.progressLegend, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Montant.
          Text('Combien voulez-vous payer ?', style: AppTextStyles.label.copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          AmountField(
            controller: amountCtrl,
            onChanged: controller.setAmount,
            errorText: controller.amountError.value,
          ),
          const SizedBox(height: 10),
          Text(
            'Vous pouvez payer en plusieurs fois. Minimum: ${CurrencyFormatter.format(PaymentController.minAmount)} par paiement.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 18),
          // Operateur.
          Text('Payer avec', style: AppTextStyles.label.copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OperatorCard(
                  name: 'MTN Mobile Money',
                  selected: controller.operator.value == Operator.MTN,
                  onTap: () => controller.setOperator(Operator.MTN),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OperatorCard(
                  name: 'Moov Money',
                  selected: controller.operator.value == Operator.MOOV,
                  onTap: () => controller.setOperator(Operator.MOOV),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Numéro à débiter.
          AppTextField(
            label: 'Numéro à débiter',
            controller: phoneCtrl,
            hintText: '01 97 12 34 56',
            prefixText: AppConstants.phoneCode,
            keyboardType: TextInputType.phone,
            onChanged: controller.setPhone,
            errorText: controller.phoneError.value,
          ),
        ],
      ),
    ));
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller});
  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.up,
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 12, AppSpacing.screen, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Frais pour vous', style: AppTextStyles.subtitle),
                Text('Aucun', style: AppTextStyles.bodyStrong.copyWith(fontSize: 15, color: AppColors.statusOk)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: 'Payer',
            onPressed: controller.pay,
            isLoading: controller.paying.value,
          ),
        ],
      ),
    ));
  }
}
