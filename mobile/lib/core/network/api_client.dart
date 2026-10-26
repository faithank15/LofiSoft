import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../data/cache/auth_storage.dart';
import '../constants/app_config.dart';
import '../errors/app_exception.dart';
import 'json_utils.dart';

/// Client HTTP unique de l'application.
/// - ajoute le jeton `Authorization: Bearer ...` quand une session existe ;
/// - applique le timeout réseau ;
/// - transforme les erreurs en exceptions typées (AppException) ;
/// - sur un 401 avec jeton (session expirée), efface la session locale.
///
/// Il ne navigue JAMAIS : c'est aux contrôleurs et aux middlewares de réagir.
/// Enregistré dans main.dart : `Get.put(ApiClient(authStorage: Get.find()))`.
class ApiClient {
  ApiClient({required AuthStorage authStorage, http.Client? client})
      : _auth = authStorage,
        _client = client ?? http.Client();

  final AuthStorage _auth;
  final http.Client _client;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path')
        .replace(queryParameters: query?.isEmpty ?? true ? null : query);
    final token = _auth.token;
    final hadToken = token != null && token.isNotEmpty;

    final request = http.Request(method, uri)
      ..headers.addAll(<String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (hadToken) 'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(AppConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Le serveur met trop de temps à répondre.');
    } on http.ClientException {
      throw const NetworkException();
    }

    return _handle(response, hadToken: hadToken);
  }

  Future<Map<String, dynamic>> _handle(http.Response response, {required bool hadToken}) async {
    Object? decoded;
    try {
      decoded = response.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      decoded = null;
    }
    final map = decoded is Map ? asJsonMap(decoded) : <String, dynamic>{'data': decoded};
    final code = response.statusCode;

    if (code >= 200 && code < 300) return map;

    if (code == 401) {
      if (hadToken) {
        await _auth.clear();
        throw const UnauthorizedException();
      }
      throw UnauthorizedException(_message(map) ?? 'E-mail ou mot de passe incorrect.');
    }
    if (code == 422 || code == 400) {
      throw ValidationException(_firstError(map) ?? 'Certaines informations sont invalides.');
    }
    if (code >= 500) throw const ServerException();
    throw ServerException(_message(map) ?? 'La requête a échoué.');
  }

  String? _message(Map<String, dynamic> map) {
    final m = map['message'];
    return m is String && m.isNotEmpty ? m : null;
  }

  /// Laravel renvoie `{"message": "...", "errors": {"champ": ["texte", ...]}}`.
  String? _firstError(Map<String, dynamic> map) {
    final errors = asJsonMap(map['errors']);
    for (final value in errors.values) {
      final list = asJsonList(value);
      if (list.isNotEmpty && list.first is String) return list.first as String;
    }
    return _message(map);
  }
}
