import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/status_text.dart';
import '../../components/molecules/app_bottom_nav.dart';
import '../../components/molecules/payment_row.dart';
import 'rent_tracking_controller.dart';

/// Mes paiements · B5 : l'historique, regroupé par mois de loyer.
class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentTrackingController>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Barre de titre : flèche retour + titre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  const AppBackButton(),
                  Text('Mes paiements', style: AppTextStyles.section),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final months = controller.history;

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  children: [
                    if (months.isEmpty)
                       Container(
                        margin: EdgeInsets.only(top: Get.height / 3 ),
                        child: 
                          Center(
                            child: Text('Aucun historique de paiement', style: TextStyle(fontSize: 20),),
                          ),
                        
                      )
                    else
                      for (final month in months) ...[
                        // Titre du mois + statut
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                monthName(month.period),
                                style: AppTextStyles.section,
                               ),
                            ),
                            StatusText(
                              _statusLabel(month),
                              kind: _statusKind(month.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Les paiements du mois
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.line),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < month.payments.length; i++)
                                PaymentRow(
                                  date: month.payments[i].date,
                                  amount: month.payments[i].amount,
                                  operator: month.payments[i].operator,
                                  isLast: i == month.payments.length - 1,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: AppNavItems.tenant,
        currentIndex: 2,
        onTap: controller.goToTab,
      ),
    );
  }
}

/// « Payé », « Impayé » ou « Partiel · 90 000 sur 150 000 ».
String _statusLabel(MonthGroup month) => switch (month.status) {
  RentStatus.paid => 'Payé',
  RentStatus.unpaid => 'Impayé',
  RentStatus.partial =>
  'Partiel · ${CurrencyFormatter.number(month.paid)} sur ${CurrencyFormatter.number(month.rent)}',
};

StatusKind _statusKind(RentStatus status) => switch (status) {
  RentStatus.paid => StatusKind.ok,
  RentStatus.partial => StatusKind.warn,
  RentStatus.unpaid => StatusKind.bad,
};