import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/remote/api_client.dart';
import 'package:mobile/data/cache/app_storage.dart';
import 'package:mobile/data/cache/auth_storage.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/domain/models/search_preferences.dart';
import 'package:mobile/domain/models/user_model.dart';

/// Session en mémoire : pas de disque dans les tests.
class MemoryAuthStorage extends AuthStorage {
  String? _token;
  UserModel? _user;

  @override
  String? get token => _token;
  @override
  UserRole? get role => _user?.role;
  @override
  UserModel? get user => _user;
  @override
  bool get hasSession => (_token ?? '').isNotEmpty && _user != null;

  @override
  Future<void> saveSession({required String token, required UserModel user}) async {
    _token = token;
    _user = user;
  }

  @override
  Future<void> clear() async {
    _token = null;
    _user = null;
  }
}

class MemoryAppStorage extends AppStorage {
  SearchPreferences _prefs = const SearchPreferences();
  bool _done = false;
  final _cache = <String, Object?>{};

  @override
  bool get onboardingDone => _done;
  @override
  Future<void> markOnboardingDone() async => _done = true;
  @override
  SearchPreferences get preferences => _prefs;
  @override
  Future<void> savePreferences(SearchPreferences value) async => _prefs = value;
  @override
  Future<void> clearPreferences() async => _prefs = const SearchPreferences();
  @override
  Future<void> saveJson(String key, Object? value) async => _cache[key] = value;
  @override
  T? readJson<T>(String key) => _cache[key] as T?;
}

/// Requête interceptée par [FakeServer].
class Seen {
  Seen(this.request, this.body);
  final http.BaseRequest request;
  final String body;
  String get method => request.method;
  String get path => request.url.path;
  Map<String, String> get query => request.url.queryParameters;
  Map<String, dynamic> get json => body.isEmpty ? {} : jsonDecode(body) as Map<String, dynamic>;
}

/// Faux serveur HTTP : `on('POST', '/auth/login', ...)` puis un vrai [ApiClient] branché dessus.
class FakeServer {
  FakeServer({MemoryAuthStorage? storage}) : auth = storage ?? MemoryAuthStorage() {
    client = ApiClient(authStorage: auth, client: MockClient.streaming(_handle));
  }

  final MemoryAuthStorage auth;
  late final ApiClient client;
  final seen = <Seen>[];
  final _routes = <String, Future<http.Response> Function(Seen)>{};
  Object? failWith;

  void on(String method, String path, {int status = 200, Object? body}) =>
      _routes['$method $path'] = (_) async => http.Response(
            body is String ? body : jsonEncode(body ?? {}),
            status,
            headers: {'content-type': 'application/json'},
          );

  void onRaw(String method, String path, Future<http.Response> Function(Seen) handler) =>
      _routes['$method $path'] = handler;

  Seen get last => seen.last;

  Future<http.StreamedResponse> _handle(http.BaseRequest request, http.ByteStream stream) async {
    final body = utf8.decode(await stream.toBytes(), allowMalformed: true);
    final s = Seen(request, body);
    seen.add(s);
    if (failWith != null) throw failWith!;
    final route = _routes['${request.method} ${request.url.path.replaceFirst('/api', '')}'];
    final response = route == null
        ? http.Response('{"message":"Ressource introuvable."}', 404)
        : await route(s);
    return http.StreamedResponse(
      http.ByteStream.fromBytes(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

const userJson = {
  'id': 'u1',
  'nom': 'Agossa',
  'prenoms': 'Patrick',
  'email': 'patrick@lofi.bj',
  'telephone': '0197123456',
  'role': 'TENANT',
  'actif': true,
};

Map<String, dynamic> announcementJson(int n, {bool favorite = false, String type = 'ROOM', int rent = 50000}) => {
      'id': 'a$n',
      'title': 'Annonce $n',
      'type': type,
      'rent': rent,
      'deposit_months': 2,
      'city': 'Cotonou',
      'district': 'Akpakpa',
      'rooms': 1,
      'photos': <String>[],
      'verified': false,
      'is_favorite': favorite,
      'status': 'PUBLISHED',
      'published_at': '2026-10-20T09:00:00Z',
    };
