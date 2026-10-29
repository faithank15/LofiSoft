import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/repo/auth_repository.dart';
import '../../../domain/models/enums.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';

/// Logique des écrans Connexion (A5) et Inscription (A6).
///
/// RÈGLE : aucun TextEditingController ici. Les pages les créent et les libèrent.
/// Les pages passent les textes saisis en paramètres des méthodes.
///
/// À ADAPTER si besoin (voir LISEZ-MOI) : les signatures `login` et `register`
/// d'AuthRepository, et les constantes de AppRoutes.
class AuthController extends GetxController {
  AuthController({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

  // ---- État observable --------------------------------------------------
  /// Mot de passe masqué ou non (œil du champ).
  final RxBool hidePassword = true.obs;

  /// Case « J'accepte les conditions » de l'inscription.
  final RxBool acceptedTerms = false.obs;

  /// Profil choisi à l'inscription.
  final Rx<UserRole> role = UserRole.TENANT.obs;

  final Rx<LoadStatus> status = LoadStatus.initial.obs;

  /// Message d'erreur du serveur à afficher au-dessus du bouton.
  final RxnString errorMessage = RxnString();

  bool get isLoading => status.value == LoadStatus.loading;

  void togglePassword() => hidePassword.toggle();

  void selectRole(UserRole value) => role.value = value;

  // ---- Actions ----------------------------------------------------------
  Future<void> login({required String email, required String password}) async {
    if (isLoading) return;
    status.value = LoadStatus.loading;
    errorMessage.value = null;
    try {
      final user = await _repository.login(email: email.trim(), password: password);
      status.value = LoadStatus.loaded;
      Get.offAllNamed(_homeRouteFor(user.role));
    } on AppException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Une erreur inattendue est survenue.');
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (isLoading) return;
    status.value = LoadStatus.loading;
    errorMessage.value = null;
    try {
      await _repository.register(
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.replaceAll(RegExp(r'\s'), ''),
        password: password,
        role: role.value,
      );
      status.value = LoadStatus.loaded;
      // Un nouveau compte passe par l'onboarding de son rôle (critères du locataire,
      // ou étapes du propriétaire avec la demande du badge Vérifié).
      Get.offAllNamed(
        role.value == UserRole.OWNER ? AppRoutes.onboardingProprietaire : AppRoutes.onboardingVille,
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

  /// Écran d'accueil de chaque profil.
  String _homeRouteFor(UserRole role) => switch (role) {
        UserRole.TENANT => AppRoutes.rentTracking,
        UserRole.OWNER => AppRoutes.ownerDashboard,
        UserRole.ADMIN => AppRoutes.admin,
      };
}
