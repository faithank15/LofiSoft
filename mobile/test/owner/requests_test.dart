import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/data/remote/fakes/fake_owner_dashboard_service.dart';
import 'package:mobile/data/remote/services/owner_dashboard_service.dart';
import 'package:mobile/data/repo/owner_dashboard_repository.dart';
import 'package:mobile/domain/models/owner_dashboard_model.dart';
import 'package:mobile/domain/models/user_model.dart';
import 'package:mobile/presentation/features/owner_dashboard/owner_dashboard_controller.dart';
import 'package:mobile/presentation/shared/load_status.dart';

import '../support/fakes.dart';

Map<String, dynamic> requestJson(String id, {String name = 'Patrick Agossa', String? phone = '0197123456'}) => {
      'rental_id': id,
      'tenant_name': name,
      'tenant_phone': phone,
      'housing': 'Studio',
      'requested_at': DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String(),
    };

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.testMode = true;
  });
  tearDown(Get.reset);

  late FakeServer server;
  setUp(() => server = FakeServer());

  OwnerDashboardRepository repo() => OwnerDashboardRepository(OwnerDashboardService(server.client));

  void stubDashboard() {
    server.on('GET', '/owner/dashboard', body: {
      'month': '2026-11', 'expected': 100000, 'received': 0, 'late_count': 0, 'tenants_count': 0, 'housings_count': 1,
    });
    server.on('GET', '/owner/tenants', body: []);
  }

  group('RentalRequest (modèle)', () {
    test('lit une ligne de GET /owner/requests', () {
      final r = RentalRequest.fromJson(requestJson('r1'));
      expect(r.rentalId, 'r1');
      expect(r.tenantName, 'Patrick Agossa');
      expect(r.tenantPhone, '0197123456');
      expect(r.housing, 'Studio');
      expect(r.requestedAt, isNotNull);
      expect(r.initials, 'PA');
    });

    test('nom ou téléphone absents : valeurs par défaut', () {
      final r = RentalRequest.fromJson({'rental_id': 'r', 'tenant_name': '  ', 'tenant_phone': ''});
      expect(r.tenantName, 'Locataire');
      expect(r.tenantPhone, isNull);
      expect(r.requestedAt, isNull);
    });
  });

  group('OwnerDashboardRepository : demandes', () {
    test('requests : liste brute lue', () async {
      server.on('GET', '/owner/requests', body: [requestJson('r1'), requestJson('r2')]);
      expect((await repo().requests()).map((r) => r.rentalId), ['r1', 'r2']);
    });

    test('accept / reject : bonnes routes et messages', () async {
      server.on('POST', '/owner/rentals/r1/accept', body: {'message': 'Locataire confirmé.'});
      server.on('POST', '/owner/rentals/r2/reject', body: {'message': 'Demande refusée.'});
      expect(await repo().accept('r1'), 'Locataire confirmé.');
      expect(await repo().reject('r2'), 'Demande refusée.');
    });

    test('409 : le message du serveur remonte', () async {
      server.on('POST', '/owner/rentals/r1/accept', status: 409, body: {'message': 'Ce logement est déjà occupé.'});
      await expectLater(
        repo().accept('r1'),
        throwsA(isA<AppException>().having((e) => e.message, 'm', 'Ce logement est déjà occupé.')),
      );
    });
  });

  group('OwnerDashboardController : demandes', () {
    late OwnerDashboardController c;
    setUp(() => c = OwnerDashboardController(repository: repo(), authStorage: MemoryAuthStorage()));

    testWidgets('load : les demandes sont chargées avec le tableau de bord', (tester) async {
      stubDashboard();
      server.on('GET', '/owner/requests', body: [requestJson('r1')]);
      await tester.runAsync(c.load);
      expect(c.status.value, LoadStatus.loaded);
      expect(c.requests.single.rentalId, 'r1');
    });

    testWidgets('demandes indisponibles : le tableau de bord reste affiché', (tester) async {
      stubDashboard();
      server.failWith = null; // /owner/requests absent -> 404
      await tester.runAsync(c.load);
      expect(c.status.value, LoadStatus.loaded);
      expect(c.requests, isEmpty);
    });

    void withApp(String name, Future<void> Function() body) {
      testWidgets(name, (tester) async {
        await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));
        await tester.runAsync(body);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpWidget(const SizedBox());
      });
    }

    withApp('accepter : la demande disparaît et les chiffres sont rechargés', () async {
      stubDashboard();
      server.on('GET', '/owner/requests', body: [requestJson('r1'), requestJson('r2')]);
      await c.load();
      server.on('POST', '/owner/rentals/r1/accept', body: {'message': 'Locataire confirmé.'});
      server.on('GET', '/owner/requests', body: [requestJson('r2')]);
      final before = server.seen.where((s) => s.path == '/api/owner/dashboard').length;

      await c.acceptRequest(c.requests.first);

      expect(c.requests.map((r) => r.rentalId), ['r2']);
      expect(server.seen.where((s) => s.path == '/api/owner/dashboard').length, before + 1);
      expect(c.busyRequests, isEmpty);
    });

    withApp('refuser : la demande disparaît sans recharger le tableau de bord', () async {
      stubDashboard();
      server.on('GET', '/owner/requests', body: [requestJson('r1')]);
      await c.load();
      server.on('POST', '/owner/rentals/r1/reject', body: {'message': 'Demande refusée.'});
      final before = server.seen.where((s) => s.path == '/api/owner/dashboard').length;

      await c.rejectRequest(c.requests.single);

      expect(c.requests, isEmpty);
      expect(server.seen.where((s) => s.path == '/api/owner/dashboard').length, before);
    });

    withApp('erreur (déjà traitée) : la liste est resynchronisée, verrou libéré', () async {
      stubDashboard();
      server.on('GET', '/owner/requests', body: [requestJson('r1')]);
      await c.load();
      server.on('POST', '/owner/rentals/r1/accept', status: 409, body: {'message': 'Seule une demande en attente peut être acceptée.'});
      server.on('GET', '/owner/requests', body: []);

      await c.acceptRequest(c.requests.single);

      expect(c.requests, isEmpty, reason: 'la demande n\'existe plus côté serveur');
      expect(c.busyRequests, isEmpty);
    });

    withApp('double appui : une seule réponse envoyée', () async {
      stubDashboard();
      server.on('GET', '/owner/requests', body: [requestJson('r1')]);
      await c.load();
      server.on('POST', '/owner/rentals/r1/reject', body: {'message': 'ok'});
      final r = c.requests.single;
      await Future.wait([c.rejectRequest(r), c.rejectRequest(r)]);
      expect(server.seen.where((s) => s.path.endsWith('/reject')).length, 1);
    });

    withApp('réseau coupé pendant la réponse : la demande reste', () async {
      stubDashboard();
      server.on('GET', '/owner/requests', body: [requestJson('r1')]);
      await c.load();
      server.failWith = const SocketException('unreachable');
      await c.rejectRequest(c.requests.single);
      expect(c.requests.length, 1);
      expect(c.busyRequests, isEmpty);
    });
  });

  group('Prénom du propriétaire', () {
    test('vient du compte connecté, plus de valeur en dur', () async {
      final auth = MemoryAuthStorage();
      await auth.saveSession(token: 't', user: UserModelX.owner(prenoms: 'Éric Junior'));
      expect(OwnerDashboardController(repository: repo(), authStorage: auth).ownerFirstName, 'Éric');
      expect(OwnerDashboardController(repository: repo(), authStorage: MemoryAuthStorage()).ownerFirstName, '');
    });
  });

  test('FakeOwnerDashboardService : cycle demande -> acceptée', () async {
    final r = OwnerDashboardRepository(FakeOwnerDashboardService(server.client));
    final list = await r.requests();
    expect(list, isNotEmpty);
    await r.accept(list.first.rentalId);
    expect((await r.requests()).length, list.length - 1);
    expect(server.seen, isEmpty);
  });
}

class UserModelX {
  static UserModel owner({required String prenoms}) =>
      UserModel.fromJson({...userJson, 'role': 'OWNER', 'prenoms': prenoms});
}
