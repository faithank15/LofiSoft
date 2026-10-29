import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../data/repo/announcement_repository.dart';
import '../../../domain/models/announcement_model.dart';
import '../../../domain/models/enums.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';
import 'listings_controller.dart';

/// Détail d'une annonce (A3). L'identifiant vient du chemin : /listings/details/:id.
class ListingDetailsController extends GetxController {
  ListingDetailsController({
    required AnnouncementRepository repository,
    required AuthStorage authStorage,
  })  : _repository = repository,
        _auth = authStorage;

  final AnnouncementRepository _repository;
  final AuthStorage _auth;

  final id = Get.parameters['id'] ?? '';
  final item = Rxn<AnnouncementModel>();
  final status = LoadStatus.initial.obs;
  final errorMessage = RxnString();
  final isFavorite = false.obs;
  final photoIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = LoadStatus.loading;
    errorMessage.value = null;
    try {
      final detail = await _repository.detail(id);
      item.value = detail;
      isFavorite.value = detail.isFavorite;
      status.value = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      status.value = LoadStatus.failure;
    } catch (_) {
      errorMessage.value = 'Une erreur inattendue est survenue.';
      status.value = LoadStatus.failure;
    }
  }

  Future<void> toggleFavorite() async {
    final current = item.value;
    if (current == null) return;
    if (!_auth.hasSession || _auth.role != UserRole.TENANT) {
      Get.snackbar(
        'Connexion requise',
        'Connectez-vous avec un compte locataire pour enregistrer des logements.',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (!_auth.hasSession) Get.toNamed(AppRoutes.login);
      return;
    }
    final wanted = !isFavorite.value;
    isFavorite.value = wanted;
    try {
      await _repository.setFavorite(id, favorite: wanted);
      if (Get.isRegistered<ListingsController>()) {
        Get.find<ListingsController>().applyFavorite(current, wanted);
      }
    } on AppException catch (e) {
      isFavorite.value = !wanted;
      Get.snackbar('Erreur', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
