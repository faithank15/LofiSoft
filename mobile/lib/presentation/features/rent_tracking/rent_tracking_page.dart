import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/atoms/app_avatar.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/status_text.dart';
import '../../components/molecules/app_bottom_nav.dart';
import '../../components/molecules/offline_banner.dart';
import '../../components/molecules/payment_row.dart';
import '../../components/molecules/rent_card.dart';
import '../../routes/app_routes.dart';
import 'rent_tracking_controller.dart';

/// Mon loyer · B2 (en ligne) et B6 (hors ligne) : même page, deux états.
class RentTrackingPage extends StatelessWidget {
  const RentTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentTrackingController>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Obx(() {
          final offline = controller.isOffline.value;
          final lastPayments = controller.lastPayments;

          return Column(
            children: [
              if (offline)
                OfflineBanner(lastSyncLabel: controller.lastSyncLabel),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  children: [
                    // Bandeau vert : mois, reste à payer, barre, échéance
                    RentCard(
                      monthLabel: controller.monthLabel,
                      remaining: controller.remaining,
                      paid: controller.paidThisPeriod,
                      total: controller.monthlyRent,
                      dueLabel: controller.dueLabel,
                      statusLabel: _statusLabel(controller.status),
                      statusKind: _statusKind(controller.status),
                      header: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour ${controller.tenantName}',
                            style: AppTextStyles.title
                                .copyWith(color: AppColors.surface),
                          ),
                          Text(
                            controller.housing,
                            style: AppTextStyles.subtitle
                                .copyWith(color: AppColors.mint),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Bouton de paiement : inactif hors ligne
                    AppButton(
                      label: offline
                          ? 'Payer : connexion nécessaire'
                          : 'Payer mon loyer',
                      onPressed: offline
                          ? null
                          : () => Get.toNamed(AppRoutes.payment),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Derniers paiements
                    Row(
                      children: [
                        Expanded(
                          child: Text('Derniers paiements',
                              style: AppTextStyles.section),
                        ),
                        if (!offline)
                          TextButton(
                            onPressed: () =>
                                Get.toNamed(AppRoutes.paymentHistory),
                            child: Text(
                              'Tout voir',
                              style: AppTextStyles.bodyStrong
                                  .copyWith(color: AppColors.green),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          for (var i = 0; i < lastPayments.length; i++)
                            PaymentRow(
                              date: lastPayments[i].date,
                              amount: lastPayments[i].amount,
                              operator: lastPayments[i].operator,
                              isLast: i == lastPayments.length - 1,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Propriétaire : appeler, et WhatsApp seulement en ligne
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: _cardDecoration(),
                      child: Row(
                        children: [
                          AppAvatar(name: controller.ownerName),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Votre propriétaire',
                                    style: AppTextStyles.caption),
                                Text(controller.ownerName,
                                    style: AppTextStyles.bodyStrong),
                              ],
                            ),
                          ),
                          _SquareIconButton(
                            icon: Icons.call_outlined,
                            label: 'Appeler',
                            onTap: () => Get.snackbar(
                              'Bientôt',
                              "L'appel arrive bientôt.",
                              snackPosition: SnackPosition.BOTTOM,
                            ),
                          ),
                          if (!offline) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _SquareIconButton(
                              icon: Icons.chat_bubble_outline,
                              label: 'WhatsApp',
                              onTap: () => Get.snackbar(
                                'Bientôt',
                                'WhatsApp arrive bientôt.',
                                snackPosition: SnackPosition.BOTTOM,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // TEMPORAIRE : pour voir B6 sans couper la connexion.
                    // À supprimer avant de rendre le travail.
                    TextButton(
                      onPressed: controller.toggleOffline,
                      child: const Text('Tester hors ligne (temporaire)'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
      bottomNavigationBar: AppBottomNav(
        items: AppNavItems.tenant,
        currentIndex: 2,
        onTap: controller.goToTab,
      ),
    );
  }
}

String _statusLabel(RentStatus status) => switch (status) {
  RentStatus.paid => 'Payé',
  RentStatus.partial => 'Partiel',
  RentStatus.unpaid => 'Impayé',
};

StatusKind _statusKind(RentStatus status) => switch (status) {
  RentStatus.paid => StatusKind.ok,
  RentStatus.partial => StatusKind.warn,
  RentStatus.unpaid => StatusKind.bad,
};

/// Fond blanc, bordure fine et ombre douce, comme les cartes d'annonce.
BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(AppRadius.card),
  border: Border.all(color: AppColors.line),
  boxShadow: AppShadows.soft,
);

/// Petit bouton carré à icône (appeler, WhatsApp).
class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.green, width: 2),
          ),
          child: Icon(icon, size: 22, color: AppColors.green),
        ),
      ),
    );
  }
}