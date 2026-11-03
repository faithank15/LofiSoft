import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/data/cache/auth_storage.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/domain/models/user_model.dart';
import 'package:mobile/presentation/routes/app_routes.dart';
import 'package:mobile/presentation/routes/auth_middleware.dart';
import 'package:mobile/presentation/routes/role_middleware.dart';

import '../support/fakes.dart';

UserModel user(UserRole role) => UserModel(
      id: '1',
      nom: 'N',
      prenoms: 'P',
      email: 'p@lofi.bj',
      telephone: '0197000000',
      role: role,
    );

/// Gardes de route : sans session -> connexion ; mauvais rôle -> sa propre accueil.
void main() {
  late MemoryAuthStorage auth;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    auth = MemoryAuthStorage();
    Get.put<AuthStorage>(auth);
  });
  tearDown(Get.reset);

  String? target(RouteSettings? r) => r?.name;

  group('AuthMiddleware', () {
    test('sans session : redirige vers la connexion', () {
      expect(target(AuthMiddleware().redirect('/admin')), AppRoutes.login);
    });

    test('avec session : laisse passer', () async {
      await auth.saveSession(token: 't', user: user(UserRole.TENANT));
      expect(AuthMiddleware().redirect('/rent-tracking'), isNull);
    });

    test('stockage non enregistré : ne bloque pas', () {
      Get.reset();
      expect(AuthMiddleware().redirect('/admin'), isNull);
    });
  });

  group('RoleMiddleware', () {
    final adminOnly = RoleMiddleware({UserRole.ADMIN});

    test('rôle autorisé : laisse passer', () async {
      await auth.saveSession(token: 't', user: user(UserRole.ADMIN));
      expect(adminOnly.redirect(AppRoutes.admin), isNull);
    });

    test('locataire sur une page admin : renvoyé vers Mon loyer', () async {
      await auth.saveSession(token: 't', user: user(UserRole.TENANT));
      expect(target(adminOnly.redirect(AppRoutes.admin)), AppRoutes.rentTracking);
    });

    test('propriétaire sur une page admin : renvoyé vers son tableau de bord', () async {
      await auth.saveSession(token: 't', user: user(UserRole.OWNER));
      expect(target(adminOnly.redirect(AppRoutes.admin)), AppRoutes.ownerDashboard);
    });

    test('admin sur une page propriétaire : renvoyé vers l\'administration', () async {
      await auth.saveSession(token: 't', user: user(UserRole.ADMIN));
      expect(target(RoleMiddleware({UserRole.OWNER}).redirect(AppRoutes.ownerDashboard)), AppRoutes.admin);
    });

    test('sans session : ne décide pas (c\'est AuthMiddleware)', () {
      expect(adminOnly.redirect(AppRoutes.admin), isNull);
    });

    test('AuthMiddleware passe avant RoleMiddleware', () {
      expect(AuthMiddleware().priority!, lessThan(adminOnly.priority!));
    });
  });

  test('homeRouteFor : une accueil par rôle', () {
    expect(homeRouteFor(UserRole.TENANT), AppRoutes.rentTracking);
    expect(homeRouteFor(UserRole.OWNER), AppRoutes.ownerDashboard);
    expect(homeRouteFor(UserRole.ADMIN), AppRoutes.admin);
  });
}
