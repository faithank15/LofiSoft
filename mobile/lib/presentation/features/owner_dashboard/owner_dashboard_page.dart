import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/molecules/app_bottom_nav.dart';
import '../../components/molecules/rent_gauge.dart';
import '../../components/molecules/tenant_tile.dart';
import '../../routes/app_routes.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'owner_dashboard_controller.dart';
import 'owner_dashboard_view.dart';

/// C1 : accueil du propriétaire.
class OwnerDashboardPage extends GetView<OwnerDashboardController> {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Obx(() {
        switch (controller.status.value) {
          case LoadStatus.initial:
          case LoadStatus.loading:
            return const SafeArea(child: LoadingView());

          case LoadStatus.failure:
            return SafeArea(
              child: ErrorView(
                message:
                controller.errorMessage.value ?? 'Chargement impossible.',
                onRetry: controller.load,
              ),
            );

          case LoadStatus.loaded:
            return _buildLoaded(context);
        }
      }),
      bottomNavigationBar: AppBottomNav(
        items: AppNavItems.owner,
        currentIndex: 0,
        onTap: controller.goToTab,
      ),
    );
  }

  Widget _buildLoaded(BuildContext context) {
    final data = controller.dashboard.value;
    if (data == null) return const SizedBox.shrink();

    final toFollow = controller.toFollow;
    final housings = data.housingsCount;

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // Bandeau vert : salutation, légende, jauge
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              MediaQuery.of(context).padding.top + AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.greenDeep,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour ${controller.ownerFirstName}',
                  style:
                  AppTextStyles.title.copyWith(color: AppColors.surface),
                ),
                Text(
                  '$housings logement${housings > 1 ? 's' : ''} · '
                      '${data.monthName.toLowerCase()}',
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.mint),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(color: Color(0xFF2F8F6B), label: 'Payé'),
                    SizedBox(width: AppSpacing.lg),
                    _LegendItem(color: Color(0xFFE0A526), label: 'Partiel'),
                    SizedBox(width: AppSpacing.lg),
                    _LegendItem(color: Color(0xFFC75B39), label: 'En retard'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                RentGauge(
                  label: 'Loyers de ${data.monthName.toLowerCase()}',
                  received: data.received,
                  expected: data.expected,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Actions rapides
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Nouvelle annonce',
                        onPressed: () =>
                            Get.toNamed(AppRoutes.ownerAnnouncementCreate),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        label: 'Ajouter un locataire',
                        variant: AppButtonVariant.outline,
                        onPressed: () =>
                            Get.toNamed(AppRoutes.ownerPropertyCreate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // À suivre
                Text('À suivre', style: AppTextStyles.section),
                const SizedBox(height: AppSpacing.sm),
                if (toFollow.isEmpty)
                  Text(
                    'Tous les loyers sont à jour.',
                    style: AppTextStyles.caption,
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < toFollow.length; i++)
                          TenantTile(
                            initials: toFollow[i].initials,
                            name: toFollow[i].tenantName,
                            subtitle: toFollow[i].homeSubtitle,
                            statusLabel: toFollow[i].status.label,
                            statusKind: toFollow[i].status.kind,
                            isLast: i == toFollow.length - 1,
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
}

/// Petit carré de couleur suivi d'un libellé (légende de la jauge).
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}