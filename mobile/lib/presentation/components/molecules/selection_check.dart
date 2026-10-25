import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Pastille de validation circulaire 26 px (maquettes E3 et E4).
///
/// Vide et bordée quand l'option n'est pas choisie, verte avec une coche
/// blanche quand elle l'est.
class SelectionCheck extends StatelessWidget {
  final bool selected;
  final double size;

  const SelectionCheck({
    super.key,
    required this.selected,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? AppColors.green : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.green : AppColors.line,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: size * 0.6, color: AppColors.surface)
          : null,
    );
  }
}
