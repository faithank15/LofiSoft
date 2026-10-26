import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../components/atoms/app_button.dart';
import '../routes/app_routes.dart';

/// Menu TEMPORAIRE de développement : un bouton par écran.
/// À retirer avant la livraison (voir app_pages.dart).
class DevMenuPage extends StatelessWidget {
  const DevMenuPage({super.key});

  static const _entries = <(String, String)>[
    ('Lancement (splash)', AppRoutes.splash),
    ('Connexion', AppRoutes.login),
    ('Inscription', AppRoutes.register),
    ('Onboarding', AppRoutes.onboarding),
    ('Onboarding locataire (ville)', AppRoutes.onboardingVille),
    ('Onboarding propriétaire', AppRoutes.onboardingProprietaire),
    ('Annonces', AppRoutes.listings),
    ('Suivi du loyer', AppRoutes.rentTracking),
    ('Tableau de bord propriétaire', AppRoutes.ownerDashboard),
    ('Administration', AppRoutes.admin),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Text('Menu de développement', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text('Touchez un écran pour l’ouvrir.', style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.lg),
            for (final (label, route) in _entries) ...[
              AppButton(
                label: label,
                variant: AppButtonVariant.outline,
                onPressed: () => Get.toNamed(route),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}