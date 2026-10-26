import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Une étape de la liste d'accompagnement.
class StepItem {
  const StepItem({required this.title, this.description, this.done = false});

  final String title;
  final String? description;

  /// Étape terminée : le numéro devient une coche.
  final bool done;
}

/// Liste verticale d'étapes numérotées reliées par un trait.
///
/// ```dart
/// StepList(steps: [
///   StepItem(title: 'Ajoutez votre logement', description: 'Adresse, photos, loyer'),
///   StepItem(title: 'Partagez le code', description: 'Votre locataire le saisit'),
/// ])
/// ```
class StepList extends StatelessWidget {
  const StepList({super.key, required this.steps});

  final List<StepItem> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: steps[i].done ? AppColors.green : AppColors.mint,
                          shape: BoxShape.circle,
                        ),
                        child: steps[i].done
                            ? const Icon(Icons.check_rounded, size: 20, color: AppColors.surface)
                            : Text(
                                '${i + 1}',
                                style: AppTextStyles.label.copyWith(color: AppColors.green),
                              ),
                      ),
                      if (i < steps.length - 1)
                        const Expanded(
                          child: SizedBox(width: 2, child: ColoredBox(color: AppColors.line)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < steps.length - 1 ? AppSpacing.xl : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(steps[i].title, style: AppTextStyles.bodyStrong),
                        ),
                        if (steps[i].description != null) ...[
                          const SizedBox(height: 2),
                          Text(steps[i].description!, style: AppTextStyles.subtitle),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
