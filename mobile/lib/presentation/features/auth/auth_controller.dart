import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/repo/auth_repository.dart';
import '../../../domain/models/enums.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';

/// Logique des écrans Connexion (A5) et Inscription (A6).
/// Aucun TextEditingController ici (règle stricte d'architecture GetX).
class AuthController extends GetxController {
  AuthController({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  // ---- État observable --------------------------------------------------
  final RxBool hidePassword = true.obs;
  final RxBool acceptedTerms = false.obs;
  final Rx<UserRole> role = UserRole.TENANT.obs;
  final Rx<LoadStatus> status = LoadStatus.initial.obs;
  final RxnString errorMessage = RxnString();

  /// Ouvrir la connexion ferme toute session restante : on repart toujours de zéro.
  @override
  void onInit() {
    super.onInit();
    _repository.endSessionIfAny();
  }

  bool get isLoading => status.value == LoadStatus.loading;

  void togglePassword() => hidePassword.toggle();

  void selectRole(UserRole value) => role.value = value;

  // ---- Actions ----------------------------------------------------------
  Future<void> login({required String email, required String password}) async {
    if (isLoading) return;
    status.value = LoadStatus.loading;
    errorMessage.value = null;
    try {
      final user = await _repository.login(
        email: email.trim(),
        password: password,
      );
      status.value = LoadStatus.loaded;
      Get.offAllNamed(_homeRouteFor(user.role));
    } on AppException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Une erreur inattendue est survenue.');
    }
  }

  Future<void> register({
    required String nom,
    required String prenoms,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (isLoading) return;
    status.value = LoadStatus.loading;
    errorMessage.value = null;
    try {
      await _repository.register(
        nom: nom.trim(),
        prenoms: prenoms.trim(),
        email: email.trim(),
        phone: phone.replaceAll(RegExp(r'\s'), ''),
        password: password,
        role: role.value,
      );
      status.value = LoadStatus.loaded;
      Get.offAllNamed(
        role.value == UserRole.OWNER
            ? AppRoutes.onboardingProprietaire
            : AppRoutes.onboardingVille,
      );
    } on AppException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Une erreur inattendue est survenue.');
    }
  }

  void _fail(String message) {
    errorMessage.value = message;
    status.value = LoadStatus.failure;
  }

  String _homeRouteFor(UserRole role) => switch (role) {
    UserRole.TENANT => AppRoutes.rentTracking,
    UserRole.OWNER => AppRoutes.ownerDashboard,
    UserRole.ADMIN => AppRoutes.admin,
  };
}
