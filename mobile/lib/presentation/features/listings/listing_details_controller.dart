import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../data/repo/announcement_repository.dart';
import '../../../data/repo/report_repository.dart';
import '../../../domain/models/announcement_model.dart';
import '../../../domain/models/enums.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';
import 'listings_controller.dart';

class ListingDetailsController extends GetxController {
  ListingDetailsController({
    required AnnouncementRepository repository,
    required ReportRepository reportRepository,
    required AuthStorage authStorage,
  }) : _repository = repository,
       _reportRepository = reportRepository,
       _auth = authStorage;

  final AnnouncementRepository _repository;
  final ReportRepository _reportRepository;
  final AuthStorage _auth;

  final id = Get.parameters['id'] ?? '';
  final item = Rxn<AnnouncementModel>();
  final status = LoadStatus.initial.obs;
  final errorMessage = RxnString();
  final isFavorite = false.obs;
  final photoIndex = 0.obs;
  final isReporting = false.obs;

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

  Future<bool> report({required String reason, String? details}) async {
    if (!_auth.hasSession) {
      Get.snackbar(
        'Connexion requise',
        'Veuillez vous connecter pour signaler une annonce.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.toNamed(AppRoutes.login);
      return false;
    }

    if (isReporting.value) return false;
    isReporting.value = true;

    try {
      final msg = await _reportRepository.submitReport(
        announcementId: id,
        reason: reason,
        details: details,
      );
      Get.snackbar(
        'Signalement transmis',
        msg,
        snackPosition: SnackPosition.BOTTOM,
      );
      isReporting.value = false;
      return true;
    } on AppException catch (e) {
      isReporting.value = false;
      Get.snackbar('Erreur', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      isReporting.value = false;
      Get.snackbar(
        'Erreur',
        'Impossible d’envoyer le signalement.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
