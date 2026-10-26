import 'package:get_storage/get_storage.dart';

/// Cache local de l'application : indicateurs de première ouverture et données
/// conservées pour la consultation hors connexion (échéances, reçus, coordonnées).
/// Enregistré une fois dans main.dart : `Get.put(AppStorage())`.
class AppStorage {
  final GetStorage _box = GetStorage();

  static const _kOnboardingDone = 'onboarding_done';

  /// `true` une fois l'onboarding terminé ou passé.
  bool get onboardingDone => _box.read<bool>(_kOnboardingDone) ?? false;

  Future<void> markOnboardingDone() => _box.write(_kOnboardingDone, true);

  // ---- Cache générique pour le mode hors-ligne ---------------------------
  /// Sauvegarde une donnée JSON brute sous une clé (ex. 'rent_current').
  Future<void> saveJson(String key, Object? value) => _box.write('cache_$key', value);

  /// Relit la dernière donnée sauvegardée, ou null.
  T? readJson<T>(String key) => _box.read<T>('cache_$key');
}
