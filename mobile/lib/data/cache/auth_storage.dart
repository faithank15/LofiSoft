import 'package:get_storage/get_storage.dart';

import '../../core/utils/json_utils.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/user_model.dart';

/// Session active conservée sur le téléphone : jeton, rôle et profil.
/// Enregistré par `initializeDependencies()` (lib/di/injector.dart).
class AuthStorage {
  final GetStorage _box = GetStorage();

  static const _kToken = 'auth_token';
  static const _kRole = 'auth_role';
  static const _kUser = 'auth_user';

  String? get token => _box.read<String>(_kToken);

  UserRole? get role {
    final value = _box.read<String>(_kRole);
    if (value == null) return null;
    for (final r in UserRole.values) {
      if (r.name == value) return r;
    }
    return null;
  }

  /// Profil en cache (utile hors connexion).
  UserModel? get user {
    final raw = _box.read<Object?>(_kUser);
    if (raw == null) return null;
    return UserModel.fromJson(asJsonMap(raw));
  }

  bool get hasSession => (token ?? '').isNotEmpty && role != null;

  Future<void> saveSession({required String token, required UserModel user}) async {
    await _box.write(_kToken, token);
    await _box.write(_kRole, user.role.name);
    await _box.write(_kUser, user.toJson());
  }

  Future<void> clear() async {
    await _box.remove(_kToken);
    await _box.remove(_kRole);
    await _box.remove(_kUser);
  }
}
