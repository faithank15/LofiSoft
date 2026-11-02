import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/models/property_model.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/atoms/status_text.dart';
import '../../components/molecules/app_bottom_nav.dart';
import '../../routes/app_routes.dart';
import '../../shared/empty_view.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'property_controller.dart';

/// Écran C2 : Mes logements (catalogue des biens du propriétaire).
class PropertyListPage extends GetView<PropertyController> {
  const PropertyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: controller.loadHousings,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mes logements', style: AppTextStyles.title),
                  AppButton(
                    label: '+ Ajouter',
                    expanded: false,
                    height: AppSizes.buttonSmall,
                    onPressed: () => Get.toNamed(AppRoutes.ownerHousingCreate),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(() => _buildContent(context)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Touchez un logement pour voir son locataire, sa caution et son code.',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: AppNavItems.owner,
        currentIndex: 1,
        onTap: controller.goToTab,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (controller.status.value) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const SizedBox(height: 320, child: LoadingView());

      case LoadStatus.failure:
        return SizedBox(
          height: 320,
          child: ErrorView(
            message: controller.errorMessage.value ?? 'Chargement impossible.',
            onRetry: controller.loadHousings,
          ),
        );

      case LoadStatus.loaded:
        if (controller.housings.isEmpty) {
          return const SizedBox(
            height: 320,
            child: EmptyView(
              label: 'Aucun logement enregistré',
              hint: 'Ajoutez votre premier logement pour commencer le suivi.',
              icon: Icons.apartment_outlined,
            ),
          );
        }

        return Column(
          children: controller.housings.map((housing) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _HousingTileCard(
                housing: housing,
                onTap: () {
                  final route = AppRoutes.ownerPropertyDetail.replaceFirst(
                    ':id',
                    housing.id,
                  );
                  Get.toNamed(route);
                },
              ),
            );
          }).toList(),
        );
    }
  }
}

class _HousingTileCard extends StatelessWidget {
  const _HousingTileCard({required this.housing, required this.onTap});

  final HousingModel housing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRented = housing.isRented;
    final subtitle = isRented
        ? '${housing.activeRental!.tenantName} · ${CurrencyFormatter.format(housing.rent)}'
        : '${housing.location} · ${CurrencyFormatter.format(housing.rent)}';

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    housing.title,
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            StatusText(
              housing.statusLabel,
              kind: isRented ? StatusKind.ok : StatusKind.neutral,
            ),
          ],
        ),
      ),
    );
  }
}
