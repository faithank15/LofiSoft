import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_checkbox.dart';

/// Grande carte de choix (profil, ville, type de logement). Bordure verte et coche quand choisie.
///
/// ```dart
/// SelectCard(
///   title: 'Locataire',
///   subtitle: 'Je cherche un logement',
///   leading: ChoiceIllustration(kind: ChoiceKind.tenant, size: 72),
///   selected: controller.profile.value == UserRole.TENANT,
///   onTap: () => controller.selectProfile(UserRole.TENANT),
/// )
/// ```
class SelectCard extends StatelessWidget {
  const SelectCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  /// Visuel à gauche (illustration, icône).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.green : AppColors.line,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.lg)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: AppTextStyles.section.copyWith(fontSize: 18)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: AppTextStyles.subtitle),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IgnorePointer(
                    child: AppCheckbox(value: selected, onChanged: (_) {}, round: true),
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
