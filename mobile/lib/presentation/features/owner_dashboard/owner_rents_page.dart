import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/models/owner_dashboard_model.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/molecules/app_bottom_nav.dart';
import '../../components/molecules/rent_gauge.dart';
import '../../components/molecules/tenant_tile.dart';
import '../../shared/empty_view.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'owner_dashboard_controller.dart';
import 'owner_dashboard_view.dart';

/// C7 : loyers du mois.
class OwnerRentsPage extends GetView<OwnerDashboardController> {
  const OwnerRentsPage({super.key});

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
        currentIndex: 2,
        onTap: controller.goToTab,
      ),
    );
  }

  Widget _buildLoaded(BuildContext context) {
    final data = controller.dashboard.value;
    if (data == null) return const SizedBox.shrink();

    final tenants = controller.tenants.toList();
    final late = controller.lateTenants;

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // Bandeau vert : titre, mois, jauge
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Loyers',
                        style: AppTextStyles.title
                            .copyWith(color: AppColors.surface),
                      ),
                    ),
                    _MonthSelector(title: data.monthTitle),
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
              children: [
                if (tenants.isEmpty)
                  const SizedBox(
                    height: 240,
                    child: EmptyView(
                      label: 'Aucun locataire',
                      hint: 'Les loyers apparaîtront quand un locataire '
                          'aura rejoint un de vos logements.',
                      icon: Icons.people_outline,
                    ),
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < tenants.length; i++)
                          TenantTile(
                            name: tenants[i].tenantName,
                            subtitle: tenants[i].rentsSubtitle,
                            statusLabel: tenants[i].status.label,
                            statusKind: tenants[i].status.kind,
                            extra: _carriedLabel(tenants[i], data),
                            isLast: i == tenants.length - 1,
                          ),
                      ],
                    ),
                  ),
                if (late.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Envoyer un rappel à ${late.first.firstName}',
                    variant: AppButtonVariant.outline,
                    isLoading: controller.isReminding.value,
                    onPressed: () => controller.remind(late.first),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// « dont 50 000 reportés d’octobre » (seulement s'il y a un report).
  String? _carriedLabel(TenantRent tenant, OwnerDashboard data) {
    if (tenant.carriedOver <= 0) return null;
    return 'dont ${CurrencyFormatter.number(tenant.carriedOver)} '
        'reportés ${data.carriedFromLabel}';
  }
}

/// Sélecteur de mois : visuel pour l'instant, l'API ne renvoie que le mois en cours.
class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final faded = AppColors.surface.withValues(alpha: 0.4);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chevron_left_rounded, color: faded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              title,
              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.surface),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: faded),
        ],
      ),
    );
  }
}