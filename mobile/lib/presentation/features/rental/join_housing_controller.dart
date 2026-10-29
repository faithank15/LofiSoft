import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../data/repo/rental_repository.dart';
import '../../../domain/models/rental_model.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';

/// Écran B1 « Rejoindre mon logement » : saisie du code, aperçu du logement, confirmation.
///
/// RÈGLE : aucun TextEditingController ici. La page passe le code saisi à [onCodeChanged].
class JoinHousingController extends GetxController {
  JoinHousingController({required RentalRepository repository, required AuthStorage authStorage})
      : _repository = repository,
        _auth = authStorage;

  final RentalRepository _repository;
  final AuthStorage _auth;

  /// Longueur d'un code complet, tiret compris (ex. `M4T-83P`).
  static const _codeLength = 7;

  final lookupStatus = LoadStatus.initial.obs;
  final housing = Rxn<HousingPreview>();

  /// Erreur sous le champ (code inconnu, réseau).
  final codeError = RxnString();
  final joining = false.obs;

  String _code = '';
  int _lookupToken = 0;

  Future<void> onCodeChanged(String code) async {
    _code = code;
    housing.value = null;
    codeError.value = null;
    if (code.length < _codeLength) {
      lookupStatus.value = LoadStatus.initial;
      return;
    }
    final token = ++_lookupToken;
    lookupStatus.value = LoadStatus.loading;
    try {
      final found = await _repository.lookup(code);
      if (token != _lookupToken) return;
      housing.value = found;
      lookupStatus.value = LoadStatus.loaded;
    } on AppException catch (e) {
      if (token != _lookupToken) return;
      codeError.value = e.message;
      lookupStatus.value = LoadStatus.failure;
    }
  }

  /// « Oui, c'est mon logement » : crée la location en attente de confirmation du propriétaire.
  Future<void> confirm() async {
    if (joining.value || housing.value == null) return;
    if (!_auth.hasSession) {
      Get.snackbar(
        'Connexion requise',
        'Connectez-vous pour rejoindre un logement.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.toNamed(AppRoutes.login);
      return;
    }
    joining.value = true;
    try {
      await _repository.join(_code);
      Get.snackbar(
        'Demande envoyée',
        'Votre propriétaire doit confirmer votre arrivée.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(AppRoutes.rentTracking);
    } on AppException catch (e) {
      codeError.value = e.message;
    } finally {
      joining.value = false;
    }
  }

  /// « Ce n'est pas le bon logement » : on repart d'un champ vide.
  void reset() {
    _lookupToken++;
    _code = '';
    housing.value = null;
    codeError.value = null;
    lookupStatus.value = LoadStatus.initial;
  }
}
