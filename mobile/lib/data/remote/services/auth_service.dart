import 'package:get/get.dart';

import '../api_client.dart';
import '../../../domain/models/enums.dart';

/// Appels HTTP bruts d'authentification. Ne décide de rien : renvoie le JSON du serveur.
class AuthService extends GetxService {
  AuthService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> login({required String email, required String password}) =>
      _api.post('/auth/login', body: {'email': email, 'password': password});

  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    required String password,
    required UserRole role,
  }) =>
      _api.post('/auth/register', body: {
        'nom': nom,
        'prenoms': prenoms,
        'email': email,
        'telephone': telephone,
        'password': password,
        'role': role.name,
      });

  Future<Map<String, dynamic>> me() => _api.get('/auth/me');

  Future<Map<String, dynamic>> forgotPassword(String email) =>
      _api.post('/auth/forgot-password', body: {'email': email});

  Future<Map<String, dynamic>> logout() => _api.post('/auth/logout');

  /// Envoie la pièce d'identité et le selfie (déjà téléversés) pour vérification.
  Future<Map<String, dynamic>> submitIdentity({
    required String idImageUrl,
    required String selfieUrl,
  }) =>
      _api.post('/me/identity', body: {'id_image_url': idImageUrl, 'selfie_url': selfieUrl});
}
