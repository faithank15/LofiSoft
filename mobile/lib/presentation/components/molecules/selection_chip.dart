import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Pastille de sélection (ville, quartier) — maquette E2.
///
/// Hauteur 48, coins arrondis 24, coche blanche quand la pastille est active.
class SelectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.line,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: AppColors.surface),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ).copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.surface : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
