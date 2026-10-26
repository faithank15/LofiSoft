import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../routes/app_pages.dart';
import '../../routes/app_routes.dart';

/// Contrôleur de l'écran d'accueil E1 (choix de profil).
///
/// Ne contient que de la logique de navigation et des variables réactives.
/// Aucun TextEditingController ni GlobalKey ici (règle d'or GetX du projet).
class WelcomeController extends GetxController {
  /// L'utilisateur choisit le rôle Locataire -> écran Ville (E2).
  void choisirLocataire() {
    Get.toNamed(AppRoutes.onboardingVille);
  }

  /// L'utilisateur choisit le rôle Propriétaire -> écran Bienvenue propriétaire (E5).
  void choisirProprietaire() {
    _allerOuInformer(AppRoutes.onboardingProprietaire);
  }

  /// L'utilisateur a déjà un compte -> écran Connexion (A5).
  void dejaUnCompte() {
    _allerOuInformer(AppRoutes.login);
  }

  /// Navigue vers [route] si elle est implémentée, sinon prévient l'utilisateur.
  void _allerOuInformer(String route) {
    if (!AppPages.hasRoute(route)) {
      Get.snackbar(
        'Bientôt disponible',
        'Cet écran arrive dans une prochaine version.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.green.withValues(alpha: 0.9),
        colorText: AppColors.surface,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    Get.toNamed(route);
  }
}
