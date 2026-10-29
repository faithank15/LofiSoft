import 'package:get_storage/get_storage.dart';

import '../../core/network/json_utils.dart';
import '../../domain/models/search_preferences.dart';

/// Cache local de l'application : indicateurs de première ouverture et données
/// conservées pour la consultation hors connexion (échéances, reçus, coordonnées).
/// Enregistré une fois dans main.dart : `Get.put(AppStorage())`.
class AppStorage {
  late final GetStorage _box = GetStorage();

  static const _kOnboardingDone = 'onboarding_done';

  /// `true` une fois l'onboarding terminé ou passé.
  bool get onboardingDone => _box.read<bool>(_kOnboardingDone) ?? false;

  Future<void> markOnboardingDone() => _box.write(_kOnboardingDone, true);

  static const _kPreferences = 'search_preferences';

  /// Critères de recherche choisis pendant l'onboarding locataire.
  SearchPreferences get preferences {
    final raw = _box.read<Object?>(_kPreferences);
    return raw == null ? const SearchPreferences() : SearchPreferences.fromJson(asJsonMap(raw));
  }

  Future<void> savePreferences(SearchPreferences value) => _box.write(_kPreferences, value.toJson());

  Future<void> clearPreferences() => _box.remove(_kPreferences);

  // ---- Cache générique pour le mode hors-ligne ---------------------------
  /// Sauvegarde une donnée JSON brute sous une clé (ex. 'rent_current').
  Future<void> saveJson(String key, Object? value) => _box.write('cache_$key', value);

  /// Relit la dernière donnée sauvegardée, ou null.
  T? readJson<T>(String key) => _box.read<T>('cache_$key');
}
