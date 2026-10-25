import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Données décrivant une étape au sein de la [StepList].
class StepListItem {
  final int number;
  final String title;
  final String description;

  const StepListItem({
    required this.number,
    required this.title,
    required this.description,
  });
}

/// Liste verticale d'étapes d'accompagnement reliées par une ligne continue.
///
/// Composant central de l'écran E6 (`E6-Proprio-etapes.html`).
class StepList extends StatelessWidget {
  const StepList({
    super.key,
    required this.items,
    this.indicatorSize = 44.0,
    this.gapBetweenSteps = 30.0,
  });

  /// Liste des étapes ordonnées à afficher.
  final List<StepListItem> items;

  /// Diamètre de la pastille numérotée.
  final double indicatorSize;

  /// Espacement vertical entre chaque étape.
  final double gapBetweenSteps;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++)
          _StepItemRow(
            item: items[i],
            isLast: i == items.length - 1,
            indicatorSize: indicatorSize,
            bottomPadding: i == items.length - 1 ? 0.0 : gapBetweenSteps,
          ),
      ],
    );
  }
}

class _StepItemRow extends StatelessWidget {
  const _StepItemRow({
    required this.item,
    required this.isLast,
    required this.indicatorSize,
    required this.bottomPadding,
  });

  final StepListItem item;
  final bool isLast;
  final double indicatorSize;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: indicatorSize,
            child: Column(
              children: [
                Container(
                  width: indicatorSize,
                  height: indicatorSize,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.number}',
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.surface,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2.0, color: AppColors.line)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.section.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.muted,
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
