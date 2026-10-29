import 'package:get/get.dart';

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
    Get.toNamed(AppRoutes.onboardingProprietaire);
  }

  /// L'utilisateur a déjà un compte -> écran Connexion (A5).
  void dejaUnCompte() {
    Get.toNamed(AppRoutes.login);
  }
}
