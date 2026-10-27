import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Une option du sélecteur : un titre et une courte phrase.
class RoleOption {
  const RoleOption({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

/// Sélecteur à bascule « Locataire / Propriétaire » (écran Inscription).
/// Composant générique : il ne connaît pas `UserRole`, il renvoie l'INDEX choisi.
class RoleSegment extends StatelessWidget {
  const RoleSegment({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<RoleOption> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _Segment(
              option: options[i],
              selected: i == selectedIndex,
              onTap: () => onChanged(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.button);
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.title}, ${option.subtitle}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.surface,
          borderRadius: radius,
          border: selected
              ? null
              : Border.all(color: AppColors.line, width: 1.5),
          boxShadow: selected ? AppShadows.button : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: selected ? AppColors.surface : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      option.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.mint : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
