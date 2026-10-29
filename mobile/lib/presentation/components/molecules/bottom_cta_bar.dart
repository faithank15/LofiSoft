import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';

/// Zone d'action basse : bouton principal et, en dessous, une action secondaire.
///
/// ```dart
/// BottomCtaBar(
///   primaryLabel: 'Continuer',
///   onPrimary: controller.next,
///   secondaryLabel: 'Voir tous les logements',
///   onSecondary: controller.voirTous,
/// )
/// ```
///
/// Le composant ne dessine **aucun fond** : c'est l'écran parent qui fournit
/// la couleur (papier sur E2 → E4, vert foncé sur E5). Les boutons, eux, sont
/// les mêmes partout (atome `AppButton`).
class BottomCtaBar extends StatelessWidget {
  const BottomCtaBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
    this.primaryVariant = AppButtonVariant.primary,
    this.secondaryVariant = AppButtonVariant.text,
  });

  /// Libellé du bouton principal.
  final String primaryLabel;

  /// Action du bouton principal.
  final VoidCallback? onPrimary;

  /// Libellé de l'action secondaire (optionnelle).
  final String? secondaryLabel;

  /// Action de l'action secondaire.
  final VoidCallback? onSecondary;

  /// `true` : le bouton principal affiche un indicateur de chargement.
  final bool isLoading;

  /// Variante du bouton principal (surface sur fond vert foncé).
  final AppButtonVariant primaryVariant;

  /// Variante de l'action secondaire.
  final AppButtonVariant secondaryVariant;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: primaryLabel,
              onPressed: onPrimary,
              isLoading: isLoading,
              variant: primaryVariant,
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: secondaryLabel!,
                onPressed: onSecondary,
                variant: secondaryVariant,
                height: AppSizes.tap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
