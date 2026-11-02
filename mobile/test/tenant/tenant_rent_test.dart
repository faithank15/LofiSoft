import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/data/remote/fakes/fake_rental_service.dart';
import 'package:mobile/data/remote/services/rental_service.dart';
import 'package:mobile/data/repo/tenant_rent_repository.dart';
import 'package:mobile/domain/models/tenant_rent_model.dart';
import 'package:mobile/domain/models/user_model.dart';
import 'package:mobile/presentation/features/rent_tracking/rent_tracking_controller.dart';
import 'package:mobile/presentation/features/rent_tracking/rent_tracking_page.dart';
import 'package:mobile/presentation/routes/app_routes.dart';
import 'package:mobile/presentation/shared/load_status.dart';

import '../support/fakes.dart';

const situationActive = {
  'status': 'ACTIVE',
  'rental_id': 'r1',
  'housing': {'id': 'h1', 'title': 'Appartement 1A', 'city': 'Cotonou', 'district': 'Fidjrossè', 'rent': 150000, 'due_day': 5},
  'owner': {'name': 'Koffi Mensah', 'telephone': '0197000002'},
};

Map<String, dynamic> payment(String id, int amount, String period, {String status = 'SUCCESS', String op = 'MTN'}) => {
      'id': id,
      'amount': amount,
      'operator': op,
      'period': period,
      'status': status,
      'paid_at': '2026-11-03T10:00:00Z',
    };

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.testMode = true;
  });
  tearDown(Get.reset);

  late FakeServer server;
  late MemoryAppStorage app;
  setUp(() {
    server = FakeServer();
    app = MemoryAppStorage();
  });

  TenantRentRepository repo() => TenantRentRepository(RentalService(server.client), app);

  void stubActive({List<Map<String, dynamic>>? payments}) {
    server.on('GET', '/me/situation', body: situationActive);
    server.on('GET', '/me/rent', body: {
      'period': '2026-11', 'total': 150000, 'paid': 90000, 'remaining': 60000, 'due_date': '2026-11-05', 'status': 'PARTIAL',
    });
    server.on('GET', '/me/payments', body: {
      'data': payments ?? [payment('p1', 40000, '2026-11'), payment('p2', 50000, '2026-11'), payment('p3', 150000, '2026-10', op: 'MOOV')],
    });
  }

  group('Modèles', () {
    test('situation : trois phases', () {
      expect(TenantSituation.fromJson({'status': 'NONE'}).phase, RentalPhase.none);
      expect(TenantSituation.fromJson({'status': 'PENDING'}).phase, RentalPhase.pending);
      expect(TenantSituation.fromJson(situationActive).phase, RentalPhase.active);
      expect(TenantSituation.fromJson({}).phase, RentalPhase.none);
    });

    test('situation : libellé du logement et propriétaire', () {
      final s = TenantSituation.fromJson(situationActive);
      expect(s.housingLabel, 'Appartement 1A · Fidjrossè, Cotonou');
      expect(s.ownerName, 'Koffi Mensah');
      expect(s.ownerPhone, '0197000002');
      expect(s.rent, 150000);
      expect(s.dueDay, 5);
    });

    test('résumé du mois', () {
      final r = RentSummary.fromJson({'period': '2026-11', 'total': 150000, 'paid': 90000, 'remaining': 60000, 'due_date': '2026-11-05'});
      expect(r.periodDate, DateTime(2026, 11));
      expect(r.dueDate, DateTime(2026, 11, 5));
      expect(r.remaining, 60000);
    });

    test('paiement : opérateur lisible, mois, réussite', () {
      final p = PaymentRecord.fromJson(payment('p', 1000, '2026-10', op: 'MOOV'));
      expect(p.operatorLabel, 'Moov Money');
      expect(p.periodDate, DateTime(2026, 10));
      expect(p.success, true);
      expect(PaymentRecord.fromJson(payment('p', 1, '2026-10', op: 'CASH')).operatorLabel, 'Espèces');
      expect(PaymentRecord.fromJson(payment('p', 1, '2026-10', status: 'FAILED')).success, false);
    });
  });

  group('TenantRentRepository', () {
    test('location active : situation, loyer et paiements (réussis seulement)', () async {
      stubActive(payments: [payment('p1', 40000, '2026-11'), payment('p2', 9999, '2026-11', status: 'FAILED')]);
      final snap = await repo().load();
      expect(snap.situation.phase, RentalPhase.active);
      expect(snap.summary!.remaining, 60000);
      expect(snap.payments.map((p) => p.id), ['p1']);
      expect(snap.fromCache, false);
    });

    test('sans location : une seule requête', () async {
      server.on('GET', '/me/situation', body: {'status': 'NONE'});
      final snap = await repo().load();
      expect(snap.situation.phase, RentalPhase.none);
      expect(server.seen.length, 1);
    });

    test('demande en attente : pas de requête de loyer', () async {
      server.on('GET', '/me/situation', body: {...situationActive, 'status': 'PENDING'});
      final snap = await repo().load();
      expect(snap.situation.phase, RentalPhase.pending);
      expect(snap.summary, isNull);
      expect(server.seen.length, 1);
    });

    test('réseau coupé : dernières informations reçues, marquées comme venant du cache', () async {
      stubActive();
      await repo().load();

      server.failWith = const SocketException('unreachable');
      final snap = await repo().load();

      expect(snap.fromCache, true);
      expect(snap.situation.housingTitle, 'Appartement 1A');
      expect(snap.summary!.paid, 90000);
      expect(snap.payments.length, 3);
      expect(snap.savedAt, isNotNull);
    });

    test('réseau coupé sans cache : l\'erreur remonte', () async {
      server.failWith = const SocketException('unreachable');
      await expectLater(repo().load(), throwsA(anything));
    });

    test('erreur serveur : pas de repli silencieux sur le cache', () async {
      stubActive();
      await repo().load();
      server.on('GET', '/me/situation', status: 500, body: {'message': 'Panne.'});
      await expectLater(repo().load(), throwsA(anything));
    });
  });

  group('RentTrackingController', () {
    late MemoryAuthStorage auth;
    late RentTrackingController c;
    setUp(() async {
      auth = server.auth;
      await auth.saveSession(token: 't', user: UserModelOf.tenant());
      c = RentTrackingController(repository: repo(), authStorage: auth);
    });

    test('active : chiffres du mois, échéance, derniers paiements, historique', () async {
      stubActive();
      await c.load();

      expect(c.loadStatus.value, LoadStatus.loaded);
      expect(c.phase.value, RentalPhase.active);
      expect(c.tenantName, 'Patrick');
      expect(c.housing, 'Appartement 1A · Fidjrossè, Cotonou');
      expect(c.ownerName, 'Koffi Mensah');
      expect(c.monthLabel, 'novembre');
      expect(c.monthlyRent, 150000);
      expect(c.paidThisPeriod, 90000);
      expect(c.remaining, 60000);
      expect(c.status, RentStatus.partial);
      expect(c.dueLabel, 'Avant le 5 novembre');
      expect(c.lastPayments.length, 2);
      expect(c.history.map((g) => g.period), [DateTime(2026, 11), DateTime(2026, 10)]);
      expect(c.history.last.paid, 150000);
      expect(c.isOffline.value, false);
    });

    test('loyer entièrement payé -> statut payé, rien à payer', () async {
      stubActive();
      server.on('GET', '/me/rent', body: {'period': '2026-11', 'total': 150000, 'paid': 150000, 'remaining': 0, 'due_date': '2026-11-05'});
      await c.load();
      expect(c.status, RentStatus.paid);
      expect(c.remaining, 0);
    });

    test('aucun paiement -> statut impayé', () async {
      stubActive(payments: []);
      server.on('GET', '/me/rent', body: {'period': '2026-11', 'total': 150000, 'paid': 0, 'remaining': 150000, 'due_date': '2026-11-05'});
      await c.load();
      expect(c.status, RentStatus.unpaid);
      expect(c.lastPayments, isEmpty);
      expect(c.history, isEmpty);
    });

    test('sans location puis demande en attente', () async {
      server.on('GET', '/me/situation', body: {'status': 'NONE'});
      await c.load();
      expect(c.phase.value, RentalPhase.none);

      server.on('GET', '/me/situation', body: {...situationActive, 'status': 'PENDING'});
      await c.load();
      expect(c.phase.value, RentalPhase.pending);
      expect(c.ownerName, 'Koffi Mensah');
    });

    test('hors connexion : dernières infos affichées, bandeau hors ligne', () async {
      stubActive();
      await c.load();
      server.failWith = const SocketException('unreachable');
      await c.load();
      expect(c.loadStatus.value, LoadStatus.loaded);
      expect(c.isOffline.value, true);
      expect(c.paidThisPeriod, 90000);
      expect(c.lastSyncLabel, startsWith('Informations du'));
    });

    test('hors connexion sans cache : erreur affichée avec message', () async {
      server.failWith = const SocketException('unreachable');
      await c.load();
      expect(c.loadStatus.value, LoadStatus.failure);
      expect(c.errorMessage.value, isNotEmpty);
    });

    test('retour en ligne : le bandeau disparaît', () async {
      stubActive();
      await c.load();
      server.failWith = const SocketException('x');
      await c.load();
      server.failWith = null;
      await c.load();
      expect(c.isOffline.value, false);
    });
  });

  group('Page « Mon loyer »', () {
    Future<RentTrackingController> open(WidgetTester tester, {List<GetPage<dynamic>> pages = const []}) async {
      await tester.binding.setSurfaceSize(const Size(420, 1000));
      final c = RentTrackingController(repository: repo(), authStorage: server.auth);
      Get.put(c);
      await tester.pumpWidget(GetMaterialApp(
        home: const RentTrackingPage(),
        defaultTransition: Transition.noTransition,
        getPages: pages,
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      return c;
    }

    testWidgets('aucune location : explication et bouton pour saisir le code', (tester) async {
      server.on('GET', '/me/situation', body: {'status': 'NONE'});
      final navigated = <String>[];
      await tester.binding.setSurfaceSize(const Size(420, 1000));
      final c = RentTrackingController(repository: repo(), authStorage: server.auth);
      Get.put(c);
      await tester.pumpWidget(GetMaterialApp(
        home: const RentTrackingPage(),
        defaultTransition: Transition.noTransition,
        getPages: [GetPage(name: AppRoutes.joinHousing, page: () => const SizedBox())],
        routingCallback: (r) {
          if (r?.current != null) navigated.add(r!.current);
        },
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      expect(find.text('Rejoindre mon logement'), findsOneWidget);
      expect(find.text('Payer mon loyer'), findsNothing);

      await tester.tap(find.text('Rejoindre mon logement'));
      await tester.pump();
      expect(navigated, contains(AppRoutes.joinHousing));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('demande en attente : message et bouton actualiser', (tester) async {
      server.on('GET', '/me/situation', body: {...situationActive, 'status': 'PENDING'});
      await open(tester);
      expect(find.text('Demande envoyée'), findsOneWidget);
      expect(find.textContaining('Koffi Mensah doit confirmer'), findsOneWidget);
      expect(find.text('Actualiser'), findsOneWidget);
      expect(find.text('Payer mon loyer'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('location active : prénom, logement, reste à payer, paiements', (tester) async {
      stubActive();
      await server.auth.saveSession(token: 't', user: UserModelOf.tenant());
      await open(tester);
      expect(find.text('Bonjour Patrick'), findsOneWidget);
      expect(find.text('Appartement 1A · Fidjrossè, Cotonou'), findsOneWidget);
      expect(find.text('Payer mon loyer'), findsOneWidget);
      expect(find.text('Koffi Mensah'), findsOneWidget);
      expect(find.text('Tester hors ligne (temporaire)'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('erreur réseau sans cache : message et réessayer', (tester) async {
      server.failWith = const SocketException('unreachable');
      await open(tester);
      expect(find.text('Réessayer'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  test('FakeRentalService : aucune location -> demande -> acceptée -> loyer', () async {
    final r = TenantRentRepository(FakeRentalService(server.client), app);
    expect((await r.load()).situation.phase, RentalPhase.none);

    await FakeRentalService(server.client).join('M4T-83P');
    expect((await r.load()).situation.phase, RentalPhase.pending);

    final active = await r.load();
    expect(active.situation.phase, RentalPhase.active);
    expect(active.summary, isNotNull);
    expect(active.payments, isNotEmpty);
    expect(server.seen, isEmpty);
  });
}

class UserModelOf {
  static UserModel tenant() => UserModel.fromJson(userJson);
}
