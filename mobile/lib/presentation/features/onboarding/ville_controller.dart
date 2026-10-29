import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import 'onboarding_completion.dart';
import 'tenant_preferences.dart';

/// Contrôleur de l'écran E2 (choix de ville et quartiers — locataire).
class VilleController extends GetxController {
  /// Liste des villes proposées.
  static const _cities = [
    'Cotonou',
    'Abomey-Calavi',
    'Porto-Novo',
    'Parakou',
    'Autre ville',
  ];

  /// Quartiers disponibles par ville.
  static const Map<String, List<String>> _neighborhoodsByCity = {
    'Cotonou': ['Fidjrossè', 'Haie Vive', 'Akpakpa', 'Cadjèhoun', 'Agla', 'Godomey'],
    'Abomey-Calavi': ['Godomey', 'Akassato', 'Zinvié', 'Ouèdo', 'Gbazaké'],
    'Porto-Novo': ['Hogbonou', 'Missérété', 'Agoungbo', 'Djrin'],
    'Parakou': ['Centre', 'Peulh', 'Zongo', 'Banikanni', 'Koupéla'],
    'Autre ville': [],
  };

  /// Ville actuellement sélectionnée.
  final selectedCity = 'Cotonou'.obs;

  /// Quartiers sélectionnés pour la ville courante.
  ///
  /// Sélection initiale alignée sur la maquette E2 (Fidjrossè, Haie Vive).
  final selectedNeighborhoods = <String>{'Fidjrossè', 'Haie Vive'}.obs;

  /// Retourne la liste des villes.
  List<String> get cities => _cities;

  /// Retourne la liste des quartiers de la ville sélectionnée.
  List<String> get neighborhoods => _neighborhoodsByCity[selectedCity.value] ?? [];

  /// Indique si une ville est sélectionnée.
  bool isCitySelected(String city) => selectedCity.value == city;

  /// Indique si un quartier est sélectionné.
  bool isNeighborhoodSelected(String neighborhood) =>
      selectedNeighborhoods.contains(neighborhood);

  /// Sélectionne une ville et réinitialise ses quartiers.
  void selectCity(String city) {
    selectedCity.value = city;
    selectedNeighborhoods.clear();
  }

  /// Bascule la sélection d'un quartier.
  void toggleNeighborhood(String neighborhood) {
    if (selectedNeighborhoods.contains(neighborhood)) {
      selectedNeighborhoods.remove(neighborhood);
    } else {
      selectedNeighborhoods.add(neighborhood);
    }
  }

  /// Navigue vers l'écran suivant (choix du type de logement — E3).
  Future<void> continuer() async {
    await TenantPreferences.enregistrer(
      city: selectedCity.value,
      neighborhoods: selectedNeighborhoods.toList(),
    );
    Get.toNamed(AppRoutes.onboardingType);
  }

  /// Action « Passer » : quitte le parcours locataire sans aller au bout.
  Future<void> passer() => OnboardingCompletion.terminerLocataire();
}
