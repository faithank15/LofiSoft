import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/repo/auth_repository.dart';
import '../../shared/load_status.dart';

/// Écran « Mot de passe oublié ».
///
/// Contrôleur à part (et non `AuthController`) : `AuthController` ferme la session à sa création,
/// ce qui déconnecterait un utilisateur déjà connecté qui ouvre cet écran depuis son profil.
class ForgotPasswordController extends GetxController {
  ForgotPasswordController({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

  final Rx<LoadStatus> status = LoadStatus.initial.obs;
  final RxnString errorMessage = RxnString();

  /// Vrai quand la demande a été envoyée.
  final RxBool sent = false.obs;

  bool get isLoading => status.value == LoadStatus.loading;

  /// Le serveur répond pareil que l'adresse existe ou non (on ne révèle pas quels comptes existent).
  Future<void> send(String email) async {
    if (isLoading) return;
    status.value = LoadStatus.loading;
    errorMessage.value = null;
    try {
      await _repository.forgotPassword(email.trim());
      status.value = LoadStatus.loaded;
      sent.value = true;
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
}
