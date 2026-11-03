import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/cache/auth_storage.dart';
import '../../domain/models/enums.dart';
import 'app_routes.dart';

/// Page d'accueil de chaque rôle.
String homeRouteFor(UserRole role) => switch (role) {
      UserRole.TENANT => AppRoutes.rentTracking,
      UserRole.OWNER => AppRoutes.ownerDashboard,
      UserRole.ADMIN => AppRoutes.admin,
    };

/// Garde de route : une page n'est ouverte que par les rôles autorisés.
/// Un autre rôle est renvoyé vers SA page d'accueil (un locataire qui tape
/// `/admin` retombe sur « Mon loyer »).
///
/// Confort d'interface seulement : le serveur répond 403 de toute façon.
class RoleMiddleware extends GetMiddleware {
  RoleMiddleware(this.allowed);

  final Set<UserRole> allowed;

  /// Passe après AuthMiddleware.
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthStorage>()) return null;
    final role = Get.find<AuthStorage>().role;
    // Sans session, c'est AuthMiddleware qui s'en charge.
    if (role == null || allowed.contains(role)) return null;
    return RouteSettings(name: homeRouteFor(role));
  }
}
