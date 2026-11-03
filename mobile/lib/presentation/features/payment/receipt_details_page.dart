import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_format.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/atoms/skyline_band.dart';
import '../../components/molecules/info_row.dart';
import '../../routes/app_routes.dart';
import 'payment_controller.dart';

class ReceiptDetailsPage extends StatelessWidget {
  const ReceiptDetailsPage({super.key});

  void _shareReceipt(receipt) {
    final text =
        'Reçu de paiement LofiSoft\n'
        'Référence : ${receipt.reference}\n'
        'Montant : ${CurrencyFormatter.format(receipt.amount)}\n'
        'Date : ${AppDateFormat.long(receipt.paidAt)}\n'
        'Opérateur : ${receipt.operator}\n'
        'Logement : ${receipt.housing}\n'
        'Période : ${receipt.period}';

    SharePlus.instance.share(
      ShareParams(text: text, subject: 'Reçu de loyer LofiSoft'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentController>();
    final receipt = controller.receipt.value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Get.offAllNamed(AppRoutes.rentTracking);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Column(
          children: [
            // Bandeau d'en-tête vert foncé avec illustration skyline
            Container(
              height: 340,
              width: double.infinity,
              color: AppColors.greenDeep,
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SkylineBand(height: 80),
                  ),
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(
                              color: AppColors.paper,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 48,
                              color: AppColors.green,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Paiement réussi',
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.surface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            CurrencyFormatter.format(receipt?.amount ?? 0),
                            style: AppTextStyles.amount.copyWith(
                              color: AppColors.surface,
                              fontSize: 38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Détails du reçu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  children: [
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'Date',
                            value: AppDateFormat.long(
                              receipt?.paidAt ?? DateTime.now(),
                            ),
                            showDivider: true,
                          ),
                          InfoRow(
                            label: 'Payé avec',
                            value: receipt?.operator ?? 'Mobile Money',
                            showDivider: true,
                          ),
                          InfoRow(
                            label: 'Logement',
                            value: receipt?.housing.isNotEmpty == true
                                ? receipt!.housing
                                : controller.housingTitle.value,
                            showDivider: true,
                          ),
                          InfoRow(
                            label: 'Période',
                            value: receipt?.period ?? controller.period.value,
                            showDivider: true,
                          ),
                          InfoRow(
                            label: 'Référence',
                            value: receipt?.reference ?? 'RC-2026-N/A',
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Barre d'actions basse
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
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (receipt != null)
                      AppButton(
                        label: 'Partager le reçu',
                        onPressed: () => _shareReceipt(receipt),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: 'Retour à mon loyer',
                      variant: AppButtonVariant.text,
                      onPressed: () => Get.offAllNamed(AppRoutes.rentTracking),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
