import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_back_button.dart';
import '../atoms/app_logo.dart';
import '../atoms/app_wordmark.dart';
import '../atoms/skyline_band.dart';

/// Bandeau vert profond du haut des écrans Connexion et Inscription :
/// flèche de retour, logo + nom, titre, sous-titre et ligne de toits en bas.
///
/// ```dart
/// AuthHeader(title: 'Connexion', subtitle: 'Ravi de vous revoir.', height: 300)
/// AuthHeader(title: 'Créer un compte', height: 190)   // sans sous-titre, plus court
/// ```
/// Se place en haut d'un `AuthScaffold`, qui fait remonter le panneau blanc par-dessus.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.height = 300,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Hauteur minimale du bandeau (la zone du haut de l'écran est incluse).
  final double height;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height, minWidth: double.infinity),
      child: ColoredBox(
        color: AppColors.greenDeep,
        child: Stack(
          children: [
            const Positioned(left: 0, right: 0, bottom: 0, child: SkylineBand(height: 70)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.xxl + AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBack)
                      AppBackButton(onPressed: onBack, color: AppColors.surface)
                    else
                      const SizedBox(height: AppSizes.tap),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppLogo(size: 34, onDark: false),
                              SizedBox(width: 10),
                              AppWordmark(size: 20, onDark: true),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            title,
                            style: AppTextStyles.display.copyWith(
                              color: AppColors.surface,
                              fontSize: 34,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              subtitle!,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.mint.withValues(alpha: 0.85),
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
