import '../../core/errors/app_exception.dart';
import '../../core/network/json_utils.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/user_model.dart';
import '../cache/auth_storage.dart';
import '../remote/services/auth_service.dart';

/// Source de vérité de l'authentification pour les contrôleurs.
/// Orchestre le service HTTP et la session conservée sur le téléphone.
class AuthRepository {
  AuthRepository(this._service, this._storage);

  final AuthService _service;
  final AuthStorage _storage;

  /// Connecte l'utilisateur, enregistre sa session et le renvoie.
  Future<UserModel> login({required String email, required String password}) async {
    final json = await _service.login(email: email, password: password);
    return _saveSessionFrom(json);
  }

  /// Crée le compte. Si le serveur renvoie directement un jeton, la session est
  /// ouverte ; sinon on enchaîne avec une connexion.
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final (prenoms, nom) = _splitName(fullName);
    final json = await _service.register(
      nom: nom,
      prenoms: prenoms,
      email: email,
      telephone: phone,
      password: password,
      role: role,
    );
    if (_extractToken(json) != null) return _saveSessionFrom(json);
    return login(email: email, password: password);
  }

  /// Revalide la session au lancement : relit le profil (`/auth/me`) et le met en cache.
  /// Jeton refusé (401) : ApiClient a déjà effacé la session, on renvoie `null`.
  /// Autre erreur (réseau, serveur) : on garde la session en cache et on renvoie le profil connu.
  Future<UserModel?> refreshSession() async {
    final token = _storage.token;
    if (token == null || token.isEmpty) return null;
    try {
      final user = UserModel.fromJson(_extractUser(await _service.me()));
      await _storage.saveSession(token: token, user: user);
      return user;
    } on UnauthorizedException {
      await _storage.clear();
      return null;
    } on AppException {
      // Réseau coupé, serveur en panne ou erreur 5xx : on garde la session en cache.
      return _storage.user;
    }
  }

  /// Ferme la session : révoque le jeton côté serveur (sans bloquer si le réseau manque),
  /// puis efface la session locale.
  Future<void> logout() async {
    try {
      await _service.logout();
    } on AppException {
      // Le jeton local est effacé quoi qu'il arrive.
    }
    await _storage.clear();
  }

  Future<void> forgotPassword(String email) => _service.forgotPassword(email);

  // ---- Interne -----------------------------------------------------------
  Future<UserModel> _saveSessionFrom(Map<String, dynamic> json) async {
    final token = _extractToken(json);
    if (token == null) {
      throw const ServerException('Réponse inattendue du serveur (jeton absent).');
    }
    final user = UserModel.fromJson(_extractUser(json));
    await _storage.saveSession(token: token, user: user);
    return user;
  }

  /// Le jeton peut se trouver à la racine ou dans `data`, sous plusieurs noms.
  String? _extractToken(Map<String, dynamic> json) {
    for (final source in [json, asJsonMap(json['data'])]) {
      for (final key in const ['token', 'access_token', 'accessToken']) {
        final value = source[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> json) {
    final data = asJsonMap(json['data']);
    final candidate = json['user'] ?? data['user'] ?? (data.isNotEmpty ? data : json);
    return asJsonMap(candidate);
  }

  /// « Patrick Agossa » -> prénoms « Patrick », nom « Agossa » (dernier mot = nom).
  (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return ('', parts.first);
    return (parts.sublist(0, parts.length - 1).join(' '), parts.last);
  }
}
