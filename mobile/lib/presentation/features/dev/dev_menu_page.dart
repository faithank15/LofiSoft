import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../data/remote/fakes/fake_rental_service.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/user_model.dart';
import '../../components/atoms/app_button.dart';
import '../../routes/app_routes.dart';

/// Menu TEMPORAIRE de développement : un bouton par écran.
/// À retirer avant la livraison (voir app_pages.dart).
///
/// En mode fake (`USE_FAKE_API=true`), une session factice du rôle requis est
/// ouverte avant la navigation : les gardes de route laissent passer, et les
/// écrans protégés (paiement, administration…) sont accessibles directement.
class DevMenuPage extends StatelessWidget {
  const DevMenuPage({super.key});

  /// (libellé, route, paramètres, rôle requis)
  static const _entries = <(String, String, Map<String, String>?, UserRole?)>[
    ('Lancement (splash)', AppRoutes.splash, null, null),
    ('Connexion', AppRoutes.login, null, null),
    ('Inscription', AppRoutes.register, null, null),
    ('Onboarding', AppRoutes.onboarding, null, null),
    ('Onboarding locataire (ville)', AppRoutes.onboardingVille, null, null),
    ('Onboarding propriétaire', AppRoutes.onboardingProprietaire, null, null),
    ('Rejoindre mon logement', AppRoutes.joinHousing, null, UserRole.TENANT),
    ('Annonces', AppRoutes.listings, null, null),
    ('Favoris', AppRoutes.favorites, null, null),
    ('Suivi du loyer', AppRoutes.rentTracking, null, UserRole.TENANT),
    ('Payer mon loyer (B3)', AppRoutes.payment, null, UserRole.TENANT),
    ('Paiement réussi (B4 démo)', AppRoutes.paymentSuccess, {'id': 'demo'}, UserRole.TENANT),
    ('Tableau de bord propriétaire', AppRoutes.ownerDashboard, null, UserRole.OWNER),
    ('Administration', AppRoutes.admin, null, UserRole.ADMIN),
  ];

  /// Écrans qui ont besoin d'une location active (fake) pour être crédibles.
  static const _needsRental = {
    AppRoutes.joinHousing,
    AppRoutes.rentTracking,
    AppRoutes.payment,
    AppRoutes.paymentSuccess,
  };

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
            for (final (label, route, params, role) in _entries) ...[
              AppButton(
                label: label,
                variant: AppButtonVariant.outline,
                onPressed: () => _open(route, params, role),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }

  /// Ouvre l'écran demandé. En mode fake, ouvre d'abord une session factice
  /// du bon rôle pour passer les gardes de route.
  Future<void> _open(String route, Map<String, String>? params, UserRole? role) async {
    if (AppConfig.useFakeApi) {
      if (role != null) {
        await Get.find<AuthStorage>().saveSession(
          token: 'dev-token',
          user: UserModel(
            id: 'dev-${role.name.toLowerCase()}',
            nom: 'Dev',
            prenoms: 'Utilisateur',
            email: 'dev@lofi.bj',
            telephone: '0197000000',
            role: role,
          ),
        );
      }
      if (_needsRental.contains(route)) {
        // Une location active : le loyer et le paiement ont des valeurs.
        FakeRentalService.devActive();
      }
    }
    Get.toNamed(route, parameters: params);
  }
}
