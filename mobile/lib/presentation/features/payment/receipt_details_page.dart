import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_format.dart';
import '../../../domain/models/installment_model.dart';
import '../../../domain/models/receipt_model.dart';
import '../../components/atoms/app_card.dart';
import '../../components/atoms/progress_bar.dart';
import '../../components/atoms/skyline_band.dart';
import '../../components/molecules/bottom_cta_bar.dart';
import '../../components/molecules/info_row.dart';
import '../../components/molecules/receipt_summary.dart';
import '../../shared/empty_view.dart';
import 'payment_controller.dart';

/// B4 « Paiement réussi » (lot 6) : confirmation, loyer à jour, détails et reçu.
class ReceiptDetailsPage extends StatefulWidget {
  const ReceiptDetailsPage({super.key});

  @override
  State<ReceiptDetailsPage> createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends State<ReceiptDetailsPage> {
  late final PaymentController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PaymentController>();
    // Ouvert directement (menu de dev) : recharger le paiement de la route.
    controller.ensurePaid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final paid = controller.paid.value;
          if (paid == null) {
            return Column(
              children: [
                const Expanded(
                  child: EmptyView(
                    label: 'Aucun paiement à afficher',
                    hint: 'Effectuez un paiement depuis « Mon loyer ».',
                  ),
                ),
                _bottomBar(),
              ],
            );
          }
          return Column(
            children: [
              _hero(paid),
              Expanded(
                child: SingleChildScrollView(
                  child: Transform.translate(
                    offset: const Offset(0, -26),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Carte loyer à jour (même structure que B3, valeurs rafraîchies).
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
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
                        const SizedBox(height: 14),
                        // Détails du paiement (4 lignes sans dividers).
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                          child: Column(
                            children: [
                              InfoRow(
                                label: 'Date',
                                value: _dateLabel(controller.receipt.value),
                                showDivider: false,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              ),
                              InfoRow(
                                label: 'Payé avec',
                                value: paid.operatorLabel,
                                showDivider: false,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              ),
                              InfoRow(
                                label: 'Numéro',
                                value: controller.maskedPhone,
                                showDivider: false,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              ),
                              InfoRow(
                                label: 'Référence',
                                value: controller.receipt.value?.reference ?? '',
                                showDivider: false,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ), // Column
                  ), // Padding
                ), // Transform.translate
              ), // SingleChildScrollView
            ), // Expanded
            _bottomBar(),
          ],
        );
        }),
      ),
    );
  }

  Widget _hero(Installment paid) {
    return Container(
      height: 380,
      color: AppColors.greenDeep,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SkylineBand(height: 90),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 70),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: -10,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 54, color: AppColors.green),
                ),
                const SizedBox(height: 16),
                Text(
                  'Paiement réussi',
                  style: AppTextStyles.display.copyWith(fontSize: 30, color: AppColors.surface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: CurrencyFormatter.number(paid.amount),
                        style: AppTextStyles.amount.copyWith(color: AppColors.surface),
                      ),
                      TextSpan(
                        text: ' ${AppConstants.currency}',
                        style: AppTextStyles.bodyStrong.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(Receipt? receipt) {
    final paidAt = receipt?.paidAt;
    return AppDateFormat.long(paidAt ?? DateTime.now());
  }

  Widget _bottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.up,
      ),
      child: SafeArea(
        top: false,
        child: BottomCtaBar(
          primaryLabel: 'Voir mon reçu',
          onPrimary: _showReceipt,
          secondaryLabel: 'Retour à mon loyer',
          onSecondary: controller.backToRent,
        ),
      ),
    );
  }

  void _showReceipt() {
    final paid = controller.paid.value;
    if (paid == null) return;
    final receipt = controller.receipt.value;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: ReceiptSummary(
            amount: paid.amount,
            lines: [
              ReceiptLine('Date', _dateLabel(receipt)),
              ReceiptLine('Payé avec', paid.operatorLabel),
              ReceiptLine('Numéro', controller.maskedPhone),
              ReceiptLine('Référence', receipt?.reference ?? ''),
            ],
          ),
        ),
      ),
    );
  }
}