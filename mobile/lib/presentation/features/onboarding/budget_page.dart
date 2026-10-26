import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/skeletons/onboarding_scaffold.dart';
import '../../components/molecules/selection_check.dart';
import 'budget_controller.dart';

/// Écran E4 · Locataire 3 : budget (choix du budget mensuel).
///
/// Reprend la maquette E4 : trois barres vertes, titre aligné à gauche,
/// quatre tranches de budget (une par ligne) et, en pied d'écran, le bouton
/// « Voir mes logements » suivi de l'action « Voir tous les logements ».
class BudgetPage extends GetView<BudgetController> {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 3,
      onBack: () => Get.back(),
      title: 'Votre budget par mois ?',
      subtitle: 'Le loyer maximum que vous pouvez payer.',
      primaryLabel: 'Voir mes logements',
      onPrimary: controller.continuer,
      secondaryLabel: 'Voir tous les logements',
      onSecondary: controller.voirTousLesLogements,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tranches de budget (une par ligne, pleine largeur)
          Obx(
            () => Column(
              children: controller.budgets
                  .map((String budget) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BudgetOption(
                          budget: budget,
                          subtitle: controller.subtitleFor(budget),
                          selected: controller.isSelected(budget),
                          onTap: controller.selectBudget,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Option de budget (une ligne cliquable).
class _BudgetOption extends StatelessWidget {
  final String budget;
  final String subtitle;
  final bool selected;
  final ValueChanged<String> onTap;

  const _BudgetOption({
    required this.budget,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(budget),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.mint : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    budget,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SelectionCheck(selected: selected),
          ],
        ),
      ),
    );
  }
}
