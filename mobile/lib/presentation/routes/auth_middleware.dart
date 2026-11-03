import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/cache/auth_storage.dart';
import 'app_routes.dart';

/// Garde de route : une page protégée n'est ouverte qu'avec une session.
/// Sans session, on est envoyé à la connexion.
///
/// Ce n'est qu'un confort d'interface : la vraie sécurité est côté serveur
/// (jeton Sanctum + middleware `role`, qui répondent 401 / 403).
class AuthMiddleware extends GetMiddleware {
  /// Passe avant RoleMiddleware (plus petit = d'abord).
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Pas de stockage enregistré (tests, démarrage incomplet) : on ne bloque pas.
    if (!Get.isRegistered<AuthStorage>()) return null;
    if (Get.find<AuthStorage>().hasSession) return null;
    return const RouteSettings(name: AppRoutes.login);
  }
}
