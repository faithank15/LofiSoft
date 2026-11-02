import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/repo/owner_dashboard_repository.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/owner_dashboard_model.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';

/// Contrôleur du tableau de bord propriétaire (C1) et des loyers du mois (C7).
class OwnerDashboardController extends GetxController {
  OwnerDashboardController({required OwnerDashboardRepository repository})
      : _repository = repository;

  final OwnerDashboardRepository _repository;

  /// TEMPORAIRE : le prénom viendra du compte connecté.
  final ownerFirstName = 'Koffi';

  final Rx<LoadStatus> status = LoadStatus.initial.obs;
  final RxnString errorMessage = RxnString();

  final Rxn<OwnerDashboard> dashboard = Rxn<OwnerDashboard>();
  final RxList<TenantRent> tenants = <TenantRent>[].obs;

  final RxBool isReminding = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Charge les chiffres du mois et la liste des locataires.
  Future<void> load() async {
    status.value = LoadStatus.loading;
    errorMessage.value = null;

    try {
      final summary = await _repository.dashboard();
      final list = await _repository.tenants();
      dashboard.value = summary;
      tenants.assignAll(list);
      status.value = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      status.value = LoadStatus.failure;
    } catch (_) {
      errorMessage.value = 'Impossible de charger le tableau de bord.';
      status.value = LoadStatus.failure;
    }
  }

  /// Locataires à surveiller : les retards d'abord, puis les paiements partiels.
  List<TenantRent> get toFollow {
    final list = tenants
        .where((t) =>
    t.status == RentStatus.LATE || t.status == RentStatus.PARTIAL)
        .toList();
    list.sort((a, b) => _priority(a.status).compareTo(_priority(b.status)));
    return list;
  }

  List<TenantRent> get lateTenants =>
      tenants.where((t) => t.status == RentStatus.LATE).toList();

  int _priority(RentStatus s) => s == RentStatus.LATE ? 0 : 1;

  /// Envoie un rappel de paiement à un locataire.
  Future<void> remind(TenantRent tenant) async {
    if (isReminding.value) return;
    isReminding.value = true;

    try {
      final message = await _repository.remind(tenant.rentalId);
      Get.snackbar('Rappel envoyé', message, snackPosition: SnackPosition.BOTTOM);
    } on AppException catch (e) {
      Get.snackbar('Erreur', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar(
        'Erreur',
        "Impossible d'envoyer le rappel.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isReminding.value = false;
    }
  }

  /// Navigation de la barre du bas propriétaire.
  void goToTab(int index) {
    switch (index) {
      case 0:
        _open(AppRoutes.ownerDashboard);
        break;
      case 1:
        _open(AppRoutes.ownerProperties);
        break;
      case 2:
        _open(AppRoutes.ownerRents);
        break;
      case 3:
        Get.toNamed(AppRoutes.profile);
        break;
    }
  }

  /// Remplace la page actuelle, sauf si on y est déjà.
  void _open(String route) {
    if (Get.currentRoute != route) Get.offNamed(route);
  }
}