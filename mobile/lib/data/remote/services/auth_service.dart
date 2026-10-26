import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
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
}
