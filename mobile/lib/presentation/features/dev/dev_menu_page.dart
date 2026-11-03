import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/atoms/app_button.dart';
import '../../routes/app_routes.dart';

/// Menu TEMPORAIRE de développement : un bouton par écran.
/// À retirer avant la livraison (voir app_pages.dart).
class DevMenuPage extends StatelessWidget {
  const DevMenuPage({super.key});

  static const _entries = <(String, String, Map<String, String>?)>[
    ('Lancement (splash)', AppRoutes.splash, null),
    ('Connexion', AppRoutes.login, null),
    ('Inscription', AppRoutes.register, null),
    ('Onboarding', AppRoutes.onboarding, null),
    ('Onboarding locataire (ville)', AppRoutes.onboardingVille, null),
    ('Onboarding propriétaire', AppRoutes.onboardingProprietaire, null),
    ('Rejoindre mon logement', AppRoutes.joinHousing, null),
    ('Annonces', AppRoutes.listings, null),
    ('Favoris', AppRoutes.favorites, null),
    ('Suivi du loyer', AppRoutes.rentTracking, null),
    ('Payer mon loyer (B3)', AppRoutes.payment, null),
    ('Paiement réussi (B4 démo)', AppRoutes.paymentSuccess, {'id': 'demo'}),
    ('Tableau de bord propriétaire', AppRoutes.ownerDashboard, null),
    ('Administration', AppRoutes.admin, null),
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
            Text(
              'Touchez un écran pour l’ouvrir.',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (label, route, params) in _entries) ...[
              AppButton(
                label: label,
                variant: AppButtonVariant.outline,
                onPressed: () => Get.toNamed(route, parameters: params),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}
