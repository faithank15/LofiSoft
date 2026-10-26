import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/molecules/housing_scene.dart';
import '../../components/skeletons/onboarding_scaffold.dart';
import '../../components/molecules/selection_check.dart';
import 'type_controller.dart';

/// Écran E3 · Locataire 2 : type (choix du type de logement).
///
/// Reprend la maquette E3 : deux barres vertes puis une beige, titre
/// aligné à gauche, grille 2 × 2 de cartes illustrées et bouton
/// « Continuer » en pied d'écran.
class TypePage extends GetView<TypeController> {
  const TypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 2,
      onBack: () => Get.back(),
      title: 'Quel type de logement ?',
      subtitle: 'Choisissez-en un ou plusieurs.',
      primaryLabel: 'Continuer',
      onPrimary: controller.continuer,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TypeCard(
                        type: 'Chambre',
                        selected: controller.isSelected('Chambre'),
                        sceneColor: AppColors.illustrationSage,
                        scene: HousingSceneKind.chambre,
                        onTap: () => controller.toggleType('Chambre'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeCard(
                        type: 'Studio',
                        selected: controller.isSelected('Studio'),
                        sceneColor: AppColors.illustrationPeach,
                        scene: HousingSceneKind.studio,
                        onTap: () => controller.toggleType('Studio'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TypeCard(
                        type: 'Appartement',
                        selected: controller.isSelected('Appartement'),
                        sceneColor: AppColors.illustrationMint,
                        scene: HousingSceneKind.appartement,
                        onTap: () => controller.toggleType('Appartement'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeCard(
                        type: 'Maison',
                        selected: controller.isSelected('Maison'),
                        sceneColor: AppColors.sand,
                        scene: HousingSceneKind.maison,
                        onTap: () => controller.toggleType('Maison'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de sélection d'un type de logement (illustration + libellé).
class _TypeCard extends StatelessWidget {
  final String type;
  final bool selected;
  final Color sceneColor;
  final HousingSceneKind scene;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.selected,
    required this.sceneColor,
    required this.scene,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.line,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.16),
              blurRadius: 26,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              height: 112,
              color: sceneColor,
              child: HousingScene(kind: scene),
            ),
            // Libellé + indicateur de sélection
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      type,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SelectionCheck(selected: selected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
