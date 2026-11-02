import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/repo/owner_announcement_repository.dart';
import '../../../data/repo/property_repository.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/property_model.dart';
import '../../components/molecules/photo_picker.dart';
import '../../routes/app_routes.dart';

/// Logique de la création d'annonce en deux étapes (C3 : où ? ; C4 : prix et photos).
/// Les champs de texte vivent dans la page, ici seulement l'état et les envois.
class ListingFormController extends GetxController {
  ListingFormController({
    required OwnerAnnouncementRepository repository,
    required PropertyRepository properties,
    ImagePicker? imagePicker,
  })  : _repository = repository,
        _properties = properties,
        _imagePicker = imagePicker ?? ImagePicker();

  final OwnerAnnouncementRepository _repository;
  final PropertyRepository _properties;
  final ImagePicker _imagePicker;

  static const maxPhotos = 10;

  /// 0 = étape 1 (C3), 1 = étape 2 (C4).
  final RxInt step = 0.obs;

  final RxList<HousingModel> housings = <HousingModel>[].obs;
  final Rxn<HousingModel> housing = Rxn<HousingModel>();

  /// Type choisi quand le propriétaire n'a encore aucun logement enregistré.
  final Rx<AccommodationType> type = AccommodationType.HOUSE.obs;

  /// Nombre de pièces (5 = « 5+ »).
  final RxInt rooms = 1.obs;

  /// Photos choisies sur le téléphone, dans l'ordre d'envoi.
  final RxList<PhotoItem> photos = <PhotoItem>[].obs;

  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHousings();
  }

  /// Liste les logements du propriétaire. Hors connexion, la liste peut manquer : le formulaire reste utilisable.
  Future<void> loadHousings() async {
    try {
      housings.assignAll(await _properties.list());
      if (housing.value == null && housings.isNotEmpty) housing.value = housings.first;
    } on AppException {
      // Formulaire utilisable sans logement lié.
    }
  }

  void selectHousing(HousingModel value) => housing.value = value;

  void selectType(AccommodationType value) => type.value = value;

  void selectRooms(int value) => rooms.value = value;

  void goToStep(int value) => step.value = value;

  /// Retour : de l'étape 2 vers 1, de l'étape 1 on quitte.
  void back() {
    if (step.value > 0 && !isSubmitting.value) {
      step.value = 0;
    } else if (!isSubmitting.value) {
      Get.back<void>();
    }
  }

  // ---------------------------------------------------------------- Photos

  Future<void> pickPhotos() async {
    final room = maxPhotos - photos.length;
    if (room <= 0 || isSubmitting.value) return;
    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 85, maxWidth: 1600, limit: room);
      for (final file in picked.take(room)) {
        photos.add(PhotoItem(localPath: file.path));
      }
    } catch (_) {
      _notify('Photos', "Impossible d'ouvrir la galerie.");
    }
  }

  void removePhoto(int index) {
    if (index < 0 || index >= photos.length || isSubmitting.value) return;
    photos.removeAt(index);
  }

  // --------------------------------------------------------------- Envoi

  /// Titre de l'annonce : celui du logement, sinon « Maison · Quartier ».
  String titleFor(String district) {
    final linked = housing.value;
    if (linked != null && linked.title.trim().isNotEmpty) return linked.title.trim();
    final label = switch (type.value) {
      AccommodationType.ROOM => 'Chambre',
      AccommodationType.OTHER => 'Logement',
      AccommodationType.HOUSE => 'Maison',
    };
    return '$label · ${district.trim()}';
  }

  /// Nombre de mois de caution pour un montant de caution donné (arrondi, jamais négatif).
  static int depositMonths({required int rent, required int deposit}) =>
      rent <= 0 || deposit <= 0 ? 0 : (deposit / rent).round();

  /// Crée puis publie l'annonce. Renvoie `true` si elle est en ligne.
  Future<bool> publish({
    required String city,
    required String district,
    required int rent,
    required int deposit,
    String? description,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final linked = housing.value;
      await _repository.publish(
        NewAnnouncement(
          housingId: linked?.id,
          title: titleFor(district),
          type: linked?.type ?? type.value,
          rent: rent,
          depositMonths: depositMonths(rent: rent, deposit: deposit),
          city: city.trim(),
          district: district.trim(),
          rooms: rooms.value,
          description: description,
        ),
        photoPaths: [for (final p in photos) ?p.localPath],
      );
      _notify('Annonce publiée', 'Elle est maintenant visible des locataires.');
      Get.offNamed(AppRoutes.ownerDashboard);
      return true;
    } on AppException catch (e) {
      _notify('Publication impossible', e.message);
      return false;
    } catch (_) {
      _notify('Publication impossible', 'Une erreur inattendue est survenue.');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _notify(String title, String message) =>
      Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
}
