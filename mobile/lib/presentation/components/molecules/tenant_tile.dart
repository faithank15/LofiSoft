import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_divider.dart';
import '../atoms/status_text.dart';

/// Ligne descriptive d'un locataire : initiales, nom, logement et statut du loyer.
/// À placer dans une `AppCard` ; le trait de séparation se règle avec `isLast`.
///
/// ```dart
/// TenantTile(name: 'Éric Bio-Tchané', subtitle: 'Appartement 3C · 170 000 dus',
///            statusLabel: 'En retard', statusKind: StatusKind.bad, extra: 'dont 50 000 reportés')
/// ```
class TenantTile extends StatelessWidget {
  const TenantTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.statusLabel,
    this.statusKind = StatusKind.neutral,
    this.initials,
    this.extra,
    this.isLast = false,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final String statusLabel;
  final StatusKind statusKind;

  /// Si fourni, affiche une pastille d'initiales à gauche.
  final String? initials;

  /// Ligne supplémentaire discrète sous le sous-titre.
  final String? extra;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
            child: Row(
              children: [
                if (initials != null) ...[
                  AppAvatar(initials: initials!),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.bodyStrong),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption),
                      if (extra != null)
                        Text(
                          extra!,
                          style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                StatusText(statusLabel, kind: statusKind),
              ],
            ),
          ),
        ),
        if (!isLast) const AppDivider(),
      ],
    );
  }
}
