import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../../domain/models/tenant_rent_model.dart';
import '../../routes/app_routes.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
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
          switch (controller.loadStatus.value) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.failure:
              return ErrorView(
                message: controller.errorMessage.value ?? 'Chargement impossible.',
                onRetry: controller.load,
              );
            case LoadStatus.loaded:
              break;
          }
          if (controller.phase.value == RentalPhase.none) {
            return _NoRental(onJoin: controller.joinHousing);
          }
          if (controller.phase.value == RentalPhase.pending) {
            return _PendingRental(
              housing: controller.housing,
              ownerName: controller.ownerName,
              onRefresh: controller.load,
            );
          }

          final offline = controller.isOffline.value;
          final lastPayments = controller.lastPayments;

          return Column(
            children: [
              if (offline)
                OfflineBanner(lastSyncLabel: controller.lastSyncLabel),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.green,
                  onRefresh: controller.load,
                  child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                            controller.tenantName.isEmpty ? 'Bonjour' : 'Bonjour ${controller.tenantName}',
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
                            onTap: () => _call(controller.ownerPhone),
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
                  ],
                ),
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
/// Appelle le propriétaire (ouvre le composeur du téléphone).
Future<void> _call(String? phone) async {
  final clean = (phone ?? '').replaceAll(RegExp(r'\s+'), '');
  if (clean.isEmpty) {
    Get.snackbar('Appel indisponible', "Le numéro du propriétaire n'est pas connu.", snackPosition: SnackPosition.BOTTOM);
    return;
  }
  final uri = Uri.parse('tel:$clean');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    Get.snackbar('Appel indisponible', 'Impossible de composer le $phone.', snackPosition: SnackPosition.BOTTOM);
  }
}

/// Aucune location : le locataire saisit le code que lui a donné son propriétaire.
class _NoRental extends StatelessWidget {
  const _NoRental({required this.onJoin});

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vpn_key_outlined, size: 48, color: AppColors.muted),
          const SizedBox(height: AppSpacing.lg),
          Text('Vous n’avez pas encore de logement', textAlign: TextAlign.center, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Demandez à votre propriétaire le code de votre logement, puis saisissez-le ici.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Rejoindre mon logement', onPressed: onJoin),
        ],
      ),
    );
  }
}

/// Demande envoyée : on attend la réponse du propriétaire.
class _PendingRental extends StatelessWidget {
  const _PendingRental({required this.housing, required this.ownerName, required this.onRefresh});

  final String housing;
  final String ownerName;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 48, color: AppColors.muted),
          const SizedBox(height: AppSpacing.lg),
          Text('Demande envoyée', textAlign: TextAlign.center, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              if (housing.isNotEmpty) housing,
              if (ownerName.isNotEmpty) '$ownerName doit confirmer votre arrivée.' else 'Votre propriétaire doit confirmer votre arrivée.',
            ].join('\n'),
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Actualiser', variant: AppButtonVariant.outline, onPressed: onRefresh),
        ],
      ),
    );
  }
}
