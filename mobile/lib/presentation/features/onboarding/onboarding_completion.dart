import 'package:get/get.dart';

import '../../../data/cache/app_storage.dart';
import '../../routes/app_routes.dart';

/// Point de sortie commun aux deux parcours d'onboarding.
///
/// Les deux flux se terminent de la même façon : on marque l'onboarding comme
/// terminé (pour que l'écran de lancement ne le repropose pas au prochain
/// démarrage), puis on envoie l'utilisateur vers son espace.
///
/// - Parcours locataire (E1 → E4)  -> catalogue des annonces.
/// - Parcours propriétaire (E1 → E7) -> tableau de bord bailleur.
abstract final class OnboardingCompletion {
  /// Fin du parcours locataire : le catalogue des annonces.
  static Future<void> terminerLocataire() async {
    await Get.find<AppStorage>().markOnboardingDone();
    Get.offAllNamed(AppRoutes.listings);
  }

  /// Fin du parcours propriétaire : le tableau de bord bailleur.
  static Future<void> terminerProprietaire() async {
    await Get.find<AppStorage>().markOnboardingDone();
    Get.offAllNamed(AppRoutes.ownerDashboard);
  }
}
