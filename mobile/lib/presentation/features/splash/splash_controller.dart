import 'package:get/get.dart';

import '../../../data/cache/app_storage.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../domain/models/enums.dart';
import '../../routes/app_routes.dart';

/// Écran de lancement (E0) : laisse l'animation se jouer, regarde la session en cache,
/// puis envoie l'utilisateur au bon endroit.
///
/// Parcours :
///   1. première ouverture de l'app  -> onboarding
///   2. session active               -> l'accueil de son rôle
///   3. sinon                        -> catalogue des annonces (visiteur)
///
/// À ADAPTER (voir LISEZ-MOI) : les noms `token`, `role` et `onboardingDone`.
class SplashController extends GetxController {
  /// Durée minimale d'affichage : celle de l'animation de SplashView + une pause.
  static const _minimumDisplay = Duration(milliseconds: 2600);

  @override
  void onReady() {
    super.onReady();
    _route();
  }

  Future<void> _route() async {
    // On attend la fin de l'animation (la lecture du cache est instantanée).
    await Future<void>.delayed(_minimumDisplay);

    final auth = Get.find<AuthStorage>();
    final app = Get.find<AppStorage>();

    if (!app.onboardingDone) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }
    final token = auth.token;
    final role = auth.role;
    if (token != null && token.isNotEmpty && role != null) {
      Get.offAllNamed(switch (role) {
        UserRole.TENANT => AppRoutes.rentTracking,
        UserRole.OWNER => AppRoutes.ownerDashboard,
        UserRole.ADMIN => AppRoutes.admin,
      });
      return;
    }
    Get.offAllNamed(AppRoutes.listings);
  }
}
