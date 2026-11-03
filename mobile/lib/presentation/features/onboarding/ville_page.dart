import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/molecules/selection_chip.dart';
import '../../components/skeletons/onboarding_scaffold.dart';
import 'ville_controller.dart';

class VillePage extends StatefulWidget {
  const VillePage({super.key});

  @override
  State<VillePage> createState() => _VillePageState();
}

class _VillePageState extends State<VillePage> {
  final controller = Get.find<VilleController>();
  bool _isNavigatingBack = false;

  void _safeBack() {
    if (_isNavigatingBack) return;
    _isNavigatingBack = true;
    Get.back();
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _isNavigatingBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 0,
      totalSteps: 3,
      onBack: _safeBack,
      onSkip: controller.passer,
      title: 'Où voulez-vous habiter ?',
      subtitle: 'Nous vous montrerons d\'abord les logements de ces zones.',
      primaryLabel: 'Continuer',
      onPrimary: controller.continuer,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller.cities
                  .map(
                    (String city) => SelectionChip(
                      label: city,
                      selected: controller.isCitySelected(city),
                      onTap: () => controller.selectCity(city),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 22),
          Obx(
            () => controller.neighborhoods.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quartiers à ${controller.selectedCity.value}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: controller.neighborhoods
                            .map(
                              (String n) => SelectionChip(
                                label: n,
                                selected: controller.isNeighborhoodSelected(n),
                                onTap: () => controller.toggleNeighborhood(n),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 22),
          const _UseLocationButton(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _UseLocationButton extends StatelessWidget {
  const _UseLocationButton();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VilleController>();
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: Obx(
              () => OutlinedButton(
                onPressed: controller.locating.value ? null : controller.useMyLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  disabledForegroundColor: AppColors.muted,
                  side: const BorderSide(color: AppColors.green, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.locating.value)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                      )
                    else
                      const Icon(Icons.location_on, size: 22, color: AppColors.green),
                    const SizedBox(width: 8),
                    Text(
                      controller.locating.value ? 'Localisation...' : 'Utiliser ma position',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: controller.locating.value ? AppColors.muted : AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Message d'information ou d'erreur (position non reconnue, refus...).
          Obx(
            () => controller.locationMessage.value == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      controller.locationMessage.value!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.statusBad),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
