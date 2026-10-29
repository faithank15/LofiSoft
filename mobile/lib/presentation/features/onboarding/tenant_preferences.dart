import 'package:get/get.dart';

import '../../../data/cache/app_storage.dart';

/// Préférences collectées pendant le parcours locataire (E2 → E4).
///
/// Elles sont conservées dans le cache local (`AppStorage`) pour que l'écran
/// des annonces puisse s'y référer : sans cela, les choix de ville, de
/// quartier, de type et de budget seraient perdus à la fin du parcours.
///
/// Chaque écran enrichit la même fiche : les valeurs absentes sont conservées.
abstract final class TenantPreferences {
  /// Clé de la fiche dans le cache local.
  static const _key = 'tenant_preferences';

  /// Enregistre (ou met à jour) une partie de la fiche locataire.
  static Future<void> enregistrer({
    String? city,
    List<String>? neighborhoods,
    List<String>? types,
    String? budget,
  }) async {
    final storage = Get.find<AppStorage>();
    final current = Map<String, Object?>.from(
      storage.readJson<Map<String, Object?>>(_key) ?? const {},
    );

    if (city != null) current['city'] = city;
    if (neighborhoods != null) current['neighborhoods'] = neighborhoods;
    if (types != null) current['types'] = types;
    if (budget != null) current['budget'] = budget;

    await storage.saveJson(_key, current);
  }

  /// Relit la fiche locataire, ou une fiche vide si le parcours n'a pas été fait.
  static Map<String, Object?> lire() {
    final storage = Get.find<AppStorage>();
    return Map<String, Object?>.from(
      storage.readJson<Map<String, Object?>>(_key) ?? const {},
    );
  }
}
