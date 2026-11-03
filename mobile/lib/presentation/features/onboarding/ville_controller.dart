import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/cache/app_storage.dart';
import '../../../data/repo/geolocation_repository.dart';
import '../../../domain/constants/benin_locations.dart';
import '../../../domain/models/user_location.dart';
import '../../routes/app_routes.dart';
import 'onboarding_completion.dart';

/// Contrôleur de l'écran E2 (choix de ville et quartiers — locataire).
class VilleController extends GetxController {
  VilleController({required GeolocationRepository geolocationRepository})
      : _geolocation = geolocationRepository;

  final GeolocationRepository _geolocation;

  /// Liste des villes proposées.
  List<String> get cities => BeninLocations.cities;

  /// Quartiers disponibles par ville.
  List<String> get neighborhoods =>
      BeninLocations.neighborhoodsByCity[selectedCity.value] ?? const <String>[];

  /// Ville actuellement sélectionnée.
  final RxString selectedCity = 'Cotonou'.obs;

  /// Quartiers sélectionnés pour la ville courante.
  ///
  /// Sélection initiale alignée sur la maquette E2 (Fidjrossè, Haie Vive).
  final RxSet<String> selectedNeighborhoods = <String>{'Fidjrossè', 'Haie Vive'}.obs;

  /// Quartiers sélectionnés, en lecture simple (copie).
  Set<String> get chosenNeighborhoods => Set<String>.from(selectedNeighborhoods);

  // ---- Position de l'utilisateur ----

  /// Recherche de position en cours.
  final RxBool locating = false.obs;

  /// Message d'erreur ou d'information sur la position (affiché sous le bouton).
  final RxnString locationMessage = RxnString();

  /// Position obtenue (coordonnées + ville + quartier).
  final Rxn<UserLocation> location = Rxn<UserLocation>();

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

  /// « Utiliser ma position » : GPS + géocodage inverse, puis pré-sélection
  /// de la ville et du quartier reconnus.
  Future<void> useMyLocation() async {
    if (locating.value) return;
    locating.value = true;
    locationMessage.value = null;
    try {
      final found = await _geolocation.locate();
      location.value = found;

      final city = BeninLocations.matchCity(found.city);
      if (city == null) {
        locationMessage.value = found.label.isEmpty
            ? 'Position obtenue, mais ville non reconnue. Choisissez votre ville.'
            : 'Position obtenue : ${found.label}. Choisissez votre ville.';
        return;
      }

      selectedCity.value = city;
      final district = BeninLocations.matchNeighborhood(city, found.district);
      selectedNeighborhoods.clear();
      if (district != null) {
        selectedNeighborhoods.add(district);
        locationMessage.value = null;
      } else {
        locationMessage.value = 'Quartier non reconnu : choisissez-le ci-dessus.';
      }
    } on AppException catch (e) {
      locationMessage.value = e.message;
    } catch (_) {
      locationMessage.value = 'Impossible d\'obtenir votre position.';
    } finally {
      locating.value = false;
    }
  }

  /// Navigue vers l'écran suivant (choix du type de logement — E3).
  Future<void> continuer() async {
    final storage = Get.find<AppStorage>();
    await storage.savePreferences(storage.preferences.copyWith(
      // « Autre ville » : pas de filtre de ville.
      city: selectedCity.value == 'Autre ville' ? '' : selectedCity.value,
      neighborhoods: selectedNeighborhoods.toList(),
    ));
    Get.toNamed(AppRoutes.onboardingType);
  }

  /// Action « Passer » : quitte le parcours locataire sans aller au bout.
  Future<void> passer() => OnboardingCompletion.terminerLocataire();
}
