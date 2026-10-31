import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/repo/property_repository.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/property_model.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';

/// Contrôleur GetX gérant l'état et les flux d'actions pour le Lot 8 (Logements propriétaire).
/// Strictement exempt de tout TextEditingController ou GlobalKey.
class PropertyController extends GetxController {
  PropertyController({required PropertyRepository repository})
    : _repository = repository;

  final PropertyRepository _repository;

  final RxList<HousingModel> housings = <HousingModel>[].obs;
  final Rx<LoadStatus> status = LoadStatus.initial.obs;
  final RxnString errorMessage = RxnString();

  final Rxn<HousingModel> selectedHousing = Rxn<HousingModel>();
  final Rx<LoadStatus> detailStatus = LoadStatus.initial.obs;

  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHousings();
  }

  /// Charge la liste des logements du propriétaire.
  Future<void> loadHousings() async {
    status.value = LoadStatus.loading;
    errorMessage.value = null;

    try {
      final results = await _repository.list();
      housings.assignAll(results);
      status.value = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      status.value = LoadStatus.failure;
    } catch (_) {
      errorMessage.value = 'Impossible de charger la liste des logements.';
      status.value = LoadStatus.failure;
    }
  }

  /// Charge le détail d'un logement par son identifiant de route.
  Future<void> loadDetail(String id) async {
    detailStatus.value = LoadStatus.loading;
    errorMessage.value = null;

    try {
      final housing = await _repository.detail(id);
      selectedHousing.value = housing;
      detailStatus.value = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      detailStatus.value = LoadStatus.failure;
    } catch (_) {
      errorMessage.value = 'Impossible de charger le logement.';
      detailStatus.value = LoadStatus.failure;
    }
  }

  /// Crée un nouveau logement et actualise la liste.
  Future<HousingModel?> createHousing({
    required String title,
    required AccommodationType type,
    required int rent,
    required int dueDay,
    required String city,
    required String district,
  }) async {
    if (isSubmitting.value) return null;
    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      final created = await _repository.create(
        title: title.trim(),
        type: type,
        rent: rent,
        dueDay: dueDay,
        city: city.trim(),
        district: district.trim(),
      );
      housings.insert(0, created);
      isSubmitting.value = false;
      return created;
    } on AppException catch (e) {
      isSubmitting.value = false;
      Get.snackbar('Erreur', e.message, snackPosition: SnackPosition.BOTTOM);
      return null;
    } catch (_) {
      isSubmitting.value = false;
      Get.snackbar(
        'Erreur',
        'Une erreur inattendue est survenue lors de la création.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Résilie le bail en cours d'un logement donné.
  Future<bool> endRental({
    required String rentalId,
    required String housingId,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;

    try {
      await _repository.endRental(rentalId);

      // Met à jour l'instance détaillée affichée
      if (selectedHousing.value?.id == housingId) {
        selectedHousing.value = selectedHousing.value?.copyWith(
          clearActiveRental: true,
        );
      }

      // Met à jour la liste des logements
      final index = housings.indexWhere((h) => h.id == housingId);
      if (index != -1) {
        housings[index] = housings[index].copyWith(clearActiveRental: true);
      }

      isSubmitting.value = false;
      Get.snackbar(
        'Succès',
        'Le contrat de location a été clôturé.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on AppException catch (e) {
      isSubmitting.value = false;
      Get.snackbar('Erreur', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      isSubmitting.value = false;
      Get.snackbar(
        'Erreur',
        'Impossible de clôturer la location.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Navigation standard de la barre d'onglets propriétaire.
  void goToTab(int index) {
    switch (index) {
      case 0:
        Get.offNamed(AppRoutes.ownerDashboard);
        break;
      case 1:
        Get.offNamed(AppRoutes.ownerProperties);
        break;
      case 2:
        Get.offNamed(AppRoutes.ownerDashboard);
        break;
      case 3:
        break;
    }
  }
}
