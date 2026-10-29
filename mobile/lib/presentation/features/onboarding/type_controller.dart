import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import 'onboarding_completion.dart';
import 'tenant_preferences.dart';

/// Contrôleur de l'écran E3 (choix du type de logement — locataire).
class TypeController extends GetxController {
  /// Liste des types de logement proposés.
  static const _types = ['Chambre', 'Studio', 'Appartement', 'Maison'];

  /// Types actuellement sélectionnés.
  ///
  /// Sélection initiale alignée sur la maquette E3 (Appartement, Maison).
  final selectedTypes = <String>{'Appartement', 'Maison'}.obs;

  /// Retourne la liste des types.
  List<String> get types => _types;

  /// Indique si un type est sélectionné.
  bool isSelected(String type) => selectedTypes.contains(type);

  /// Bascule la sélection d'un type.
  void toggleType(String type) {
    if (selectedTypes.contains(type)) {
      selectedTypes.remove(type);
    } else {
      selectedTypes.add(type);
    }
  }

  /// Navigue vers l'écran suivant (choix du budget — E4).
  Future<void> continuer() async {
    await TenantPreferences.enregistrer(types: selectedTypes.toList());
    Get.toNamed(AppRoutes.onboardingBudget);
  }

  /// Action « Passer » : quitte le parcours locataire sans aller au bout.
  Future<void> passer() => OnboardingCompletion.terminerLocataire();
}
