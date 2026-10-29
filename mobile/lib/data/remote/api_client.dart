import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../cache/auth_storage.dart';
import '../../core/constants/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/json_utils.dart';

/// Client HTTP unique de l'application.
/// - ajoute le jeton `Authorization: Bearer ...` quand une session existe ;
/// - applique le timeout réseau ;
/// - transforme les erreurs en exceptions typées (AppException) ;
/// - sur un 401 avec jeton (session expirée), efface la session locale.
///
/// Il ne navigue JAMAIS : c'est aux contrôleurs et aux middlewares de réagir.
/// Enregistré par `initializeDependencies()` (lib/di/injector.dart).
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

  /// Envoi d'un fichier (multipart/form-data) avec des champs texte en plus.
  Future<Map<String, dynamic>> upload(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, String> fields = const {},
  }) async {
    final token = _auth.token;
    final hadToken = token != null && token.isNotEmpty;
    final request = http.MultipartRequest('POST', Uri.parse('${AppConfig.apiBaseUrl}$path'))
      ..headers.addAll(<String, String>{
        'Accept': 'application/json',
        if (hadToken) 'Authorization': 'Bearer $token',
      })
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileField, filePath));
    return _dispatch(request, hadToken: hadToken);
  }

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

    return _dispatch(request, hadToken: hadToken);
  }

  Future<Map<String, dynamic>> _dispatch(http.BaseRequest request, {required bool hadToken}) async {
    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(AppConfig.timeout);
      response = await http.Response.fromStream(streamed);
      if (kDebugMode) debugPrint('[api] ${request.method} ${request.url} -> ${response.statusCode}');
    } on SocketException catch (e) {
      if (kDebugMode) debugPrint('[api] ${request.method} ${request.url} -> réseau : $e');
      throw const NetworkException();
    } on TimeoutException {
      if (kDebugMode) debugPrint('[api] ${request.method} ${request.url} -> délai dépassé');
      throw const NetworkException('Le serveur met trop de temps à répondre.');
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint('[api] ${request.method} ${request.url} -> client : $e');
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
