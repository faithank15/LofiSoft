import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_button.dart';
import '../atoms/app_card.dart';
import '../atoms/status_text.dart';

/// Carte d'administration : une étiquette de motif, un titre, un contenu facultatif
/// et des boutons d'action (valider, refuser, supprimer, ignorer).
///
/// Signalement :
/// ```dart
/// AdminActionCard(
///   tagLabel: 'Annonce frauduleuse', tagKind: StatusKind.bad, meta: 'Il y a 2 h',
///   title: 'Villa 4 pièces, Calavi', subtitle: 'Propriétaire : Koffi Mensah · 2 signalements',
///   primaryLabel: 'Voir', onPrimary: ...,
///   dangerLabel: 'Supprimer', onDanger: ...,
///   tertiaryLabel: 'Ignorer', onTertiary: ...,
/// )
/// ```
/// Vérification d'identité : même carte avec `child: IdPreview(...)`,
/// `primaryLabel: 'Valider'`, `dangerLabel: 'Refuser'`.
class AdminActionCard extends StatelessWidget {
  const AdminActionCard({
    super.key,
    required this.title,
    this.tagLabel,
    this.tagKind = StatusKind.neutral,
    this.meta,
    this.subtitle,
    this.child,
    this.primaryLabel,
    this.onPrimary,
    this.dangerLabel,
    this.onDanger,
    this.tertiaryLabel,
    this.onTertiary,
  });

  final String title;
  final String? tagLabel;
  final StatusKind tagKind;

  /// Texte discret à droite de l'étiquette (ex. « Il y a 2 h »).
  final String? meta;
  final String? subtitle;

  /// Contenu libre entre le titre et les boutons (ex. aperçu de la pièce d'identité).
  final Widget? child;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? dangerLabel;
  final VoidCallback? onDanger;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tagLabel != null || meta != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (tagLabel != null) StatusText(tagLabel!, kind: tagKind) else const SizedBox.shrink(),
                if (meta != null) Text(meta!, style: AppTextStyles.caption),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.section.copyWith(fontSize: 18)),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!, style: AppTextStyles.caption),
          ],
          if (child != null) ...[const SizedBox(height: AppSpacing.md), child!],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (primaryLabel != null)
                Expanded(
                  flex: 12,
                  child: AppButton(label: primaryLabel!, onPressed: onPrimary),
                ),
              if (dangerLabel != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(flex: 12, child: _DangerButton(label: dangerLabel!, onPressed: onDanger)),
              ],
              if (tertiaryLabel != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 9,
                  child: AppButton(
                    label: tertiaryLabel!,
                    onPressed: onTertiary,
                    variant: AppButtonVariant.text,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.button,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.statusBad,
          side: const BorderSide(color: AppColors.statusBad, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: AppTextStyles.status.copyWith(fontSize: 15, color: AppColors.statusBad),
        ),
      ),
    );
  }
}
