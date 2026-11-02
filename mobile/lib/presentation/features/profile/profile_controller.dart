import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../data/repo/auth_repository.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/user_model.dart';
import '../../routes/app_routes.dart';

/// Contrôleur de la page Profil (locataire, propriétaire et administrateur).
class ProfileController extends GetxController {
  ProfileController({required AuthRepository repository, required AuthStorage storage})
      : _repository = repository,
        _storage = storage;

  final AuthRepository _repository;
  final AuthStorage _storage;

  /// Affiché tout de suite depuis le cache, puis remplacé par la version du serveur.
  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxBool isLoggingOut = false.obs;

  @override
  void onInit() {
    super.onInit();
    user.value = _storage.user;
    reload();
  }

  /// Relit le profil. Hors connexion, on garde celui du cache sans bruit.
  Future<void> reload() async {
    try {
      final fresh = await _repository.refreshSession();
      if (fresh != null) user.value = fresh;
    } on AppException {
      // Cache conservé.
    }
  }

  /// « Locataire », « Propriétaire », « Administrateur »
  String get roleLabel => switch (user.value?.role) {
        UserRole.OWNER => 'Propriétaire',
        UserRole.ADMIN => 'Administrateur',
        _ => 'Locataire',
      };

  /// Ferme la session puis revient à la connexion. Un double appui est ignoré.
  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;
    try {
      await _repository.logout();
    } finally {
      isLoggingOut.value = false;
    }
    Get.offAllNamed(AppRoutes.login);
  }
}
