import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/core/utils/date_format.dart';
import 'package:mobile/data/remote/fakes/fake_admin_service.dart';
import 'package:mobile/data/remote/services/admin_service.dart';
import 'package:mobile/data/remote/services/auth_service.dart';
import 'package:mobile/data/repo/admin_repository.dart';
import 'package:mobile/data/repo/auth_repository.dart';
import 'package:mobile/domain/models/admin_model.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/domain/models/user_model.dart';
import 'package:mobile/presentation/features/admin/admin_controller.dart';
import 'package:mobile/presentation/features/profile/profile_controller.dart';
import 'package:mobile/presentation/routes/app_routes.dart';
import 'package:mobile/presentation/shared/load_status.dart';

import '../support/fakes.dart';

String ago(Duration d) => DateTime.now().subtract(d).toUtc().toIso8601String();

Map<String, dynamic> reportJson(String id, String annId,
        {String reason = 'Annonce frauduleuse', Duration age = const Duration(hours: 2), int count = 1, String? owner = 'Koffi Mensah', String? city = 'Calavi'}) =>
    {
      'id': id,
      'reason': reason,
      'details': null,
      'status': 'PENDING',
      'created_at': ago(age),
      'reports_count': count,
      'announcement': {'id': annId, 'title': 'Villa 4 pièces', 'city': city, 'owner_name': owner},
    };

Map<String, dynamic> identityJson(String id, {String name = 'Awa Sanni', int housings = 1}) => {
      'id': id,
      'status': 'PENDING',
      'created_at': ago(const Duration(days: 1)),
      'id_image_url': 'https://x.test/id.jpg',
      'selfie_url': 'https://x.test/s.jpg',
      'owner': {'id': 'o-$id', 'name': name, 'housings_count': housings},
    };

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.testMode = true;
  });
  tearDown(Get.reset);

  late FakeServer server;
  void boot() {
    server = FakeServer();
    // load() lit aussi la liste des comptes : vide par défaut, sauf test dédié.
    server.on('GET', '/admin/users', body: {'data': []});
  }

  group('ProfileController : déconnexion', () {
    testWidgets('efface la session, révoque le jeton, retourne à la connexion', (tester) async {
      final srv = FakeServer();
      await srv.auth.saveSession(token: 't', user: UserModelOf.role('TENANT'));
      final c = ProfileController(repository: AuthRepository(AuthService(srv.client), srv.auth), storage: srv.auth);
      srv.on('POST', '/auth/logout', body: {'message': 'ok'});
      final routes = <String>[];
      await tester.pumpWidget(GetMaterialApp(
        home: const SizedBox(),
        defaultTransition: Transition.noTransition,
        transitionDuration: Duration.zero,
        getPages: [GetPage(name: AppRoutes.login, page: () => const SizedBox())],
        routingCallback: (r) {
          if (r?.current != null) routes.add(r!.current);
        },
      ));

      await tester.runAsync(() async {
        await Future.wait([c.logout(), c.logout()]);
      });
      await tester.pump(const Duration(seconds: 1));

      expect(srv.auth.hasSession, false);
      expect(routes, contains(AppRoutes.login));
      expect(srv.seen.where((s) => s.path.endsWith('/logout')).length, 1);
    });

    testWidgets('réseau coupé : la session locale est quand même effacée', (tester) async {
      final srv = FakeServer();
      await srv.auth.saveSession(token: 't', user: UserModelOf.role('TENANT'));
      final c = ProfileController(repository: AuthRepository(AuthService(srv.client), srv.auth), storage: srv.auth);
      srv.failWith = const SocketException('unreachable');
      await tester.pumpWidget(GetMaterialApp(
        home: const SizedBox(),
        defaultTransition: Transition.noTransition,
        transitionDuration: Duration.zero,
        getPages: [GetPage(name: AppRoutes.login, page: () => const SizedBox())],
      ));
      await tester.runAsync(c.logout);
      await tester.pump(const Duration(seconds: 1));
      expect(srv.auth.hasSession, false);
    });
  });

  // ------------------------------------------------------------ Utilisateurs

  Map<String, dynamic> accountJson(String id, {String role = 'TENANT', bool actif = true, bool verified = false}) => {
        'id': id,
        'nom': 'Nom$id',
        'prenoms': 'Pre$id',
        'email': '$id@lofi.bj',
        'telephone': '0197000000',
        'role': role,
        'actif': actif,
        'identity_verified': verified,
      };

  group('AdminController : utilisateurs', () {
    late AdminController c;

    void withApp(String name, Future<void> Function() body) {
      testWidgets(name, (tester) async {
        boot();
        c = AdminController(repository: AdminRepository(AdminService(server.client)));
        await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));
        await tester.runAsync(body);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpWidget(const SizedBox());
      });
    }

    void serve() {
      server.on('GET', '/admin/reports', body: []);
      server.on('GET', '/admin/identity-requests', body: []);
      server.on('GET', '/admin/users', body: {
        'data': [accountJson('u1'), accountJson('u2', role: 'OWNER', verified: true)],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 2},
      });
    }

    withApp('load : la liste vient de data (même enveloppe que les autres listes)', () async {
      serve();
      await c.load();
      expect(c.users.map((u) => u.id), ['u1', 'u2']);
      expect(c.users[1].identityVerified, true);
      expect(c.users[0].identityVerified, false);
    });

    withApp('suspendre : PUT actif=false, la ligne passe à suspendu', () async {
      serve();
      server.on('PUT', '/admin/users/u1/active', body: {'message': 'ok'});
      await c.load();
      await c.setUserActive(c.users.first, actif: false);
      expect(server.last.method, 'PUT');
      expect(server.last.path, '/api/admin/users/u1/active');
      expect(server.last.json, {'actif': false});
      expect(c.users.first.actif, false);
      expect(c.isBusy('u1'), false);
    });

    withApp('réactiver : la ligne repasse à actif', () async {
      serve();
      server.on('GET', '/admin/users', body: {'data': [accountJson('u1', actif: false)]});
      server.on('PUT', '/admin/users/u1/active', body: {'message': 'ok'});
      await c.load();
      await c.setUserActive(c.users.first, actif: true);
      expect(server.last.json, {'actif': true});
      expect(c.users.first.actif, true);
    });

    withApp('refus du serveur (422) : la ligne ne change pas, le verrou est libéré', () async {
      serve();
      server.on('PUT', '/admin/users/u1/active', status: 422, body: {'message': 'Action impossible sur votre propre compte.'});
      await c.load();
      await c.setUserActive(c.users.first, actif: false);
      expect(c.users.first.actif, true);
      expect(c.isBusy('u1'), false);
    });

    test('UserModel lit identity_verified et le recopie dans toJson', () {
      final u = UserModel.fromJson(accountJson('u9', role: 'OWNER', verified: true));
      expect(u.identityVerified, true);
      expect(u.toJson()['identity_verified'], true);
      expect(UserModel.fromJson({'id': 'x'}).identityVerified, false);
    });
  });

  // ------------------------------------------------------------- Dates

  group('AppDateFormat.ago', () {
    final now = DateTime(2026, 11, 2, 12);
    String f(Duration d) => AppDateFormat.ago(now.subtract(d), now: now);

    test('paliers', () {
      expect(f(const Duration(seconds: 20)), 'À l’instant');
      expect(f(const Duration(minutes: 5)), 'Il y a 5 min');
      expect(f(const Duration(hours: 2)), 'Il y a 2 h');
      expect(f(const Duration(hours: 30)), 'Hier');
      expect(f(const Duration(days: 3)), 'Il y a 3 jours');
      expect(f(const Duration(days: 45)), '18 sept. 2026');
    });

    test('date dans le futur : pas de texte négatif', () {
      expect(AppDateFormat.ago(now.add(const Duration(hours: 1)), now: now), 'À l’instant');
    });
  });

  // ------------------------------------------------------------ Modèles

  group('ReportItem / ReportGroup', () {
    test('lit le contrat de GET /admin/reports', () {
      final r = ReportItem.fromJson(reportJson('r1', 'a1', count: 2));
      expect(r.reason, 'Annonce frauduleuse');
      expect(r.announcementId, 'a1');
      expect(r.ownerName, 'Koffi Mensah');
      expect(r.city, 'Calavi');
      expect(r.reportsCount, 2);
      expect(r.status, ReportStatus.PENDING);
    });

    test('champs absents : valeurs par défaut sans plantage', () {
      final r = ReportItem.fromJson({'id': 'r1', 'announcement': {'id': 'a1'}});
      expect(r.reason, 'Signalement');
      expect(r.announcementTitle, 'Annonce supprimée');
      expect(r.ownerName, isNull);
      expect(r.createdAt, isNull);
    });

    test('regroupe par annonce, le plus récent en premier', () {
      final items = [
        reportJson('old', 'a1', reason: 'Prix suspect', age: const Duration(days: 2)),
        reportJson('other', 'a2', age: const Duration(hours: 5)),
        reportJson('new', 'a1', reason: 'Annonce frauduleuse', age: const Duration(hours: 1)),
      ].map(ReportItem.fromJson);
      final groups = ReportGroup.from(items);

      expect(groups.map((g) => g.announcementId), ['a1', 'a2']);
      expect(groups.first.reports.map((r) => r.id), ['new', 'old']);
      expect(groups.first.reason, 'Annonce frauduleuse');
    });

    test('libellés : titre + ville, propriétaire, pluriel', () {
      final g = ReportGroup.from([
        ReportItem.fromJson(reportJson('r1', 'a1', count: 2)),
        ReportItem.fromJson(reportJson('r2', 'a1', count: 2)),
      ]).single;
      expect(g.headline, 'Villa 4 pièces, Calavi');
      expect(g.subtitle, 'Propriétaire : Koffi Mensah · 2 signalements');

      final one = ReportGroup.from([ReportItem.fromJson(reportJson('r3', 'a3'))]).single;
      expect(one.subtitle, endsWith('1 signalement'));
    });

    test('sans ville ni propriétaire', () {
      final g = ReportGroup.from([ReportItem.fromJson(reportJson('r', 'a', owner: null, city: null))]).single;
      expect(g.headline, 'Villa 4 pièces');
      expect(g.subtitle, '1 signalement');
    });

    test('le compte du serveur prime s\'il est plus grand (signalements déjà traités)', () {
      final g = ReportGroup.from([ReportItem.fromJson(reportJson('r', 'a', count: 5))]).single;
      expect(g.count, 5);
    });
  });

  group('IdentityRequestItem', () {
    test('lit le contrat de GET /admin/identity-requests', () {
      final i = IdentityRequestItem.fromJson(identityJson('i1', housings: 2));
      expect(i.ownerName, 'Awa Sanni');
      expect(i.housingsCount, 2);
      expect(i.housingsLabel, '2 logements');
      expect(i.idImageUrl, 'https://x.test/id.jpg');
      expect(i.status, IdentityStatus.PENDING);
    });

    test('initiales et libellés de logements', () {
      expect(IdentityRequestItem.fromJson(identityJson('i', name: 'Awa Sanni')).initials, 'AS');
      expect(IdentityRequestItem.fromJson(identityJson('i', name: 'Koffi')).initials, 'K');
      expect(IdentityRequestItem.fromJson(identityJson('i', housings: 0)).housingsLabel, 'Aucun logement');
      expect(IdentityRequestItem.fromJson(identityJson('i', housings: 1)).housingsLabel, '1 logement');
    });

    test('URLs vides -> null (l\'aperçu affiche l\'icône)', () {
      final i = IdentityRequestItem.fromJson({...identityJson('i'), 'id_image_url': '', 'selfie_url': null});
      expect(i.idImageUrl, isNull);
      expect(i.selfieUrl, isNull);
    });
  });

  // ---------------------------------------------------------- Repository

  group('AdminRepository', () {
    late AdminRepository repo;
    setUp(() {
      boot();
      repo = AdminRepository(AdminService(server.client));
    });

    test('reports : liste brute du serveur lue, statut PENDING demandé', () async {
      server.on('GET', '/admin/reports', body: [reportJson('r1', 'a1')]);
      final list = await repo.reports();
      expect(list.single.id, 'r1');
      expect(server.last.query['status'], 'PENDING');
    });

    test('removeAnnouncement : action REMOVE_ANNOUNCEMENT', () async {
      server.on('POST', '/admin/reports/r1/resolve', body: {'message': 'Signalement résolu.'});
      expect(await repo.removeAnnouncement('r1'), 'Signalement résolu.');
      expect(server.last.json, {'action': 'REMOVE_ANNOUNCEMENT'});
    });

    test('dismissReport : POST /dismiss', () async {
      server.on('POST', '/admin/reports/r1/dismiss', body: {'message': 'Signalement ignoré.'});
      await repo.dismissReport('r1');
      expect(server.last.method, 'POST');
    });

    test('identityRequests / approve / reject (motif nettoyé)', () async {
      server.on('GET', '/admin/identity-requests', body: [identityJson('i1')]);
      server.on('POST', '/admin/identity-requests/i1/approve', body: {'message': 'ok'});
      server.on('POST', '/admin/identity-requests/i1/reject', body: {'message': 'Demande rejetée.'});

      expect((await repo.identityRequests()).single.id, 'i1');
      await repo.approveIdentity('i1');
      await repo.rejectIdentity('i1', reason: '  pièce illisible  ');
      expect(server.last.json, {'reason': 'pièce illisible'});
    });

    test('403 (non admin) : AppException', () async {
      server.on('GET', '/admin/reports', status: 403, body: {'message': 'Accès refusé.'});
      await expectLater(repo.reports(), throwsA(isA<AppException>()));
    });

    test('409 (déjà traitée) : message du serveur conservé', () async {
      server.on('POST', '/admin/identity-requests/i1/approve', status: 409, body: {'message': 'Cette demande a déjà été traitée.'});
      await expectLater(
        repo.approveIdentity('i1'),
        throwsA(isA<AppException>().having((e) => e.message, 'm', 'Cette demande a déjà été traitée.')),
      );
    });
  });

  // ---------------------------------------------------------- Contrôleur

  group('AdminController : chargement', () {
    late AdminController c;
    setUp(() {
      boot();
      c = AdminController(repository: AdminRepository(AdminService(server.client)));
    });

    test('load : signalements et demandes', () async {
      server.on('GET', '/admin/reports', body: [reportJson('r1', 'a1'), reportJson('r2', 'a1')]);
      server.on('GET', '/admin/identity-requests', body: [identityJson('i1')]);
      await c.load();
      expect(c.status.value, LoadStatus.loaded);
      expect(c.groups.length, 1);
      expect(c.requests.length, 1);
    });

    test('load : réseau coupé -> failure puis relance réussie', () async {
      server.failWith = const SocketException('unreachable');
      await c.load();
      expect(c.status.value, LoadStatus.failure);
      expect(c.errorMessage.value, isNotEmpty);

      server.failWith = null;
      server.on('GET', '/admin/reports', body: []);
      server.on('GET', '/admin/identity-requests', body: []);
      await c.load();
      expect(c.status.value, LoadStatus.loaded);
      expect(c.errorMessage.value, isNull);
    });
  });

  group('AdminController : actions', () {
    late AdminController c;

    void withApp(String name, Future<void> Function() body) {
      testWidgets(name, (tester) async {
        boot();
        c = AdminController(repository: AdminRepository(AdminService(server.client)));
        await tester.pumpWidget(GetMaterialApp(
          home: const SizedBox(),
          getPages: [for (final r in [AppRoutes.adminReports, AppRoutes.adminVerifications, AppRoutes.profile]) GetPage(name: r, page: () => const SizedBox())],
        ));
        await tester.runAsync(body);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpWidget(const SizedBox());
      });
    }

    Future<void> loadTwoAnnouncements() async {
      server.on('GET', '/admin/reports', body: [
        reportJson('r1', 'a1', count: 2),
        reportJson('r2', 'a1', count: 2, age: const Duration(hours: 9)),
        reportJson('r3', 'a2'),
      ]);
      server.on('GET', '/admin/identity-requests', body: [identityJson('i1'), identityJson('i2', name: 'Jean Hounkpatin')]);
      await c.load();
    }

    withApp('supprimer : tous les signalements de l\'annonce sont clos, la carte disparaît', () async {
      await loadTwoAnnouncements();
      server.on('POST', '/admin/reports/r1/resolve', body: {'message': 'ok'});
      server.on('POST', '/admin/reports/r2/resolve', body: {'message': 'ok'});

      await c.removeAnnouncement(c.groups.firstWhere((g) => g.announcementId == 'a1'));

      expect(c.groups.map((g) => g.announcementId), ['a2']);
      final resolved = server.seen.where((s) => s.path.endsWith('/resolve')).toList();
      expect(resolved.length, 2);
      expect(resolved.every((s) => s.json['action'] == 'REMOVE_ANNOUNCEMENT'), true);
      expect(c.busy, isEmpty);
    });

    withApp('ignorer : appelle dismiss pour chaque signalement', () async {
      await loadTwoAnnouncements();
      server.on('POST', '/admin/reports/r3/dismiss', body: {'message': 'ok'});
      await c.dismiss(c.groups.firstWhere((g) => g.announcementId == 'a2'));
      expect(c.groups.length, 1);
      expect(c.groups.single.announcementId, 'a1');
    });

    withApp('échec au milieu du groupe : seul ce qui est traité disparaît, verrou libéré', () async {
      await loadTwoAnnouncements();
      server.on('POST', '/admin/reports/r1/resolve', body: {'message': 'ok'});
      server.on('POST', '/admin/reports/r2/resolve', status: 500, body: {'message': 'Panne.'});

      await c.removeAnnouncement(c.groups.firstWhere((g) => g.announcementId == 'a1'));

      expect(c.reports.map((r) => r.id), ['r2', 'r3']);
      expect(c.groups.length, 2, reason: 'la carte reste visible pour réessayer');
      expect(c.busy, isEmpty);
    });

    withApp('double appui : une seule série d\'appels', () async {
      await loadTwoAnnouncements();
      server.on('POST', '/admin/reports/r3/dismiss', body: {'message': 'ok'});
      final g = c.groups.firstWhere((g) => g.announcementId == 'a2');
      await Future.wait([c.dismiss(g), c.dismiss(g)]);
      expect(server.seen.where((s) => s.path.endsWith('/dismiss')).length, 1);
    });

    withApp('valider : la demande disparaît', () async {
      await loadTwoAnnouncements();
      server.on('POST', '/admin/identity-requests/i1/approve', body: {'message': 'ok'});
      await c.approve(c.requests.first);
      expect(c.requests.map((r) => r.id), ['i2']);
    });

    withApp('valider : 409 -> la demande reste, message d\'erreur, verrou libéré', () async {
      await loadTwoAnnouncements();
      server.on('POST', '/admin/identity-requests/i1/approve', status: 409, body: {'message': 'Déjà traitée.'});
      await c.approve(c.requests.first);
      expect(c.requests.length, 2);
      expect(c.busy, isEmpty);
    });

    withApp('refuser : motif envoyé, demande retirée', () async {
      await loadTwoAnnouncements();
      server.on('POST', '/admin/identity-requests/i2/reject', body: {'message': 'ok'});
      await c.reject(c.requests.last, ' selfie flou ');
      expect(server.last.json, {'reason': 'selfie flou'});
      expect(c.requests.map((r) => r.id), ['i1']);
    });

    withApp('refuser sans motif : aucun appel réseau', () async {
      await loadTwoAnnouncements();
      final before = server.seen.length;
      await c.reject(c.requests.first, '   ');
      expect(server.seen.length, before);
      expect(c.requests.length, 2);
    });
  });

  // ------------------------------------------------------ Faux service

  group('FakeAdminService (USE_FAKE_API=true)', () {
    setUp(boot);

    test('mêmes clés que le vrai contrat, aucun appel réseau, état conservé', () async {
      final repo = AdminRepository(FakeAdminService(server.client));
      final reports = await repo.reports();
      final groups = ReportGroup.from(reports);
      expect(groups.length, 3);
      expect(groups.first.count, 2);

      await repo.dismissReport(reports.first.id);
      expect((await repo.reports()).length, reports.length - 1);

      final ids = await repo.identityRequests();
      expect(ids.length, 2);
      await repo.approveIdentity(ids.first.id);
      expect((await repo.identityRequests()).length, 1);
      await expectLater(repo.approveIdentity('nope'), throwsA(isA<AppException>()));
      expect(server.seen, isEmpty);
    });
  });

  // ------------------------------------------------------------- Profil

  group('ProfileController', () {
    late MemoryAuthStorage auth;
    late ProfileController c;

    setUp(() async {
      boot();
      auth = server.auth;
      await auth.saveSession(token: 't', user: UserModelOf.role('OWNER'));
      c = ProfileController(repository: AuthRepository(AuthService(server.client), auth), storage: auth);
    });

    test('affiche tout de suite le profil du cache', () {
      c.user.value = auth.user;
      expect(c.user.value!.fullName, 'Patrick Agossa');
      expect(c.roleLabel, 'Propriétaire');
    });

    test('reload : remplace par la version du serveur', () async {
      server.on('GET', '/auth/me', body: {'user': {...userJson, 'prenoms': 'Paul', 'role': 'OWNER'}});
      await c.reload();
      expect(c.user.value!.prenoms, 'Paul');
    });

    test('reload hors connexion : le cache est gardé sans erreur', () async {
      c.user.value = auth.user;
      server.failWith = const SocketException('unreachable');
      await c.reload();
      expect(c.user.value!.prenoms, 'Patrick');
    });

    test('libellés de rôle', () {
      for (final (role, label) in [('TENANT', 'Locataire'), ('OWNER', 'Propriétaire'), ('ADMIN', 'Administrateur')]) {
        c.user.value = UserModelOf.role(role);
        expect(c.roleLabel, label);
      }
    });
  });
}

class UserModelOf {
  static UserModel role(String r) => UserModel.fromJson({...userJson, 'role': r});
}
