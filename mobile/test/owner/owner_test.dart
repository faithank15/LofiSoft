import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/data/remote/fakes/fake_owner_dashboard_service.dart';
import 'package:mobile/data/remote/fakes/fake_property_service.dart';
import 'package:mobile/data/remote/services/owner_dashboard_service.dart';
import 'package:mobile/data/remote/services/property_service.dart';
import 'package:mobile/data/repo/owner_dashboard_repository.dart';
import 'package:mobile/data/repo/property_repository.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/domain/models/owner_dashboard_model.dart';
import 'package:mobile/domain/models/property_model.dart';
import 'package:mobile/presentation/features/owner_dashboard/owner_dashboard_controller.dart';
import 'package:mobile/presentation/features/owner_properties/property_controller.dart';
import 'package:mobile/presentation/routes/app_routes.dart';
import 'package:mobile/presentation/shared/load_status.dart';

import '../support/fakes.dart';

Map<String, dynamic> housingJson(int n, {bool rented = false}) => {
      'id': 'h$n',
      'owner_id': 'o1',
      'title': 'Logement $n',
      'type': 'HOUSE',
      'rent': 100000 * n,
      'due_day': 5,
      'city': 'Cotonou',
      'district': 'Fidjrossè',
      'code': 'CODE-$n',
      'photos': <String>[],
      if (rented)
        'active_rental': {
          'id': 'r$n',
          'tenant_id': 't$n',
          'tenant': {'id': 't$n', 'nom': 'Agossa', 'prenoms': 'Patrick', 'telephone': '0197123456'},
          'started_at': '2026-03-01T00:00:00Z',
          'status': 'ACTIVE',
        },
    };

Map<String, dynamic> tenantJson(String id, String status, {int due = 100000}) => {
      'rental_id': id,
      'tenant_name': 'Éric Bio-Tchané',
      'housing': 'Appartement 3C',
      'due': due,
      'carried_over': 0,
      'status': status,
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
  void boot() {
    server = FakeServer();
    app = MemoryAppStorage();
  }

  // ---------------------------------------------------------------- Modèles

  group('OwnerDashboard (modèle)', () {
    OwnerDashboard of({int expected = 400000, int received = 100000, String month = '2026-11'}) =>
        OwnerDashboard.fromJson({
          'month': month,
          'expected': expected,
          'received': received,
          'late_count': 2,
          'tenants_count': 4,
          'housings_count': 5,
        });

    test('lit le contrat de GET /owner/dashboard', () {
      final d = of();
      expect(d.expected, 400000);
      expect(d.received, 100000);
      expect(d.lateCount, 2);
      expect(d.tenantsCount, 4);
      expect(d.housingsCount, 5);
    });

    test('progression : 25 %, plafonnée à 100 %, 0 si rien d\'attendu', () {
      expect(of().percent, 25);
      expect(of(received: 900000).progress, 1.0);
      expect(of(expected: 0, received: 0).progress, 0);
    });

    test('libellés de mois en français', () {
      final d = of();
      expect(d.monthName, 'Novembre');
      expect(d.monthTitle, 'Novembre 2026');
      expect(d.previousMonthName, 'Octobre');
      expect(d.carriedFromLabel, 'd’octobre');
      expect(of(month: '2026-10').carriedFromLabel, 'de septembre');
    });

    test('janvier : le mois précédent est décembre', () {
      expect(of(month: '2026-01').previousMonthName, 'Décembre');
    });

    test('champs manquants ou textuels : pas de plantage', () {
      final d = OwnerDashboard.fromJson({'expected': '250000', 'received': null});
      expect(d.expected, 250000);
      expect(d.received, 0);
      expect(d.lateCount, 0);
    });
  });

  group('TenantRent (modèle)', () {
    test('lit une ligne de GET /owner/tenants', () {
      final t = TenantRent.fromJson(tenantJson('r1', 'LATE', due: 150000));
      expect(t.rentalId, 'r1');
      expect(t.status, RentStatus.LATE);
      expect(t.due, 150000);
      expect(t.paid, isNull);
      expect(t.remaining, isNull);
    });

    test('reste à payer jamais négatif', () {
      final t = TenantRent.fromJson({...tenantJson('r1', 'PARTIAL'), 'paid': 130000});
      expect(t.remaining, 0);
      final u = TenantRent.fromJson({...tenantJson('r1', 'PARTIAL'), 'paid': 40000});
      expect(u.remaining, 60000);
    });

    test('prénom, initiales, logement abrégé', () {
      final t = TenantRent.fromJson(tenantJson('r1', 'PAID'));
      expect(t.firstName, 'Éric');
      expect(t.initials, 'ÉB');
      expect(t.shortHousing, 'Appart. 3C');
    });

    test('nom vide ou d\'un seul mot', () {
      expect(TenantRent.fromJson({...tenantJson('r', 'PAID'), 'tenant_name': ''}).initials, '');
      expect(TenantRent.fromJson({...tenantJson('r', 'PAID'), 'tenant_name': 'koffi'}).initials, 'K');
    });

    test('statut inconnu -> UPCOMING', () {
      expect(TenantRent.fromJson(tenantJson('r', 'WHATEVER')).status, RentStatus.UPCOMING);
    });
  });

  group('HousingModel (modèle)', () {
    test('logement libre', () {
      final h = HousingModel.fromJson(housingJson(1));
      expect(h.isRented, false);
      expect(h.statusLabel, 'Libre');
      expect(h.location, 'Fidjrossè, Cotonou');
      expect(h.rent, 100000);
    });

    test('logement loué : locataire et statut', () {
      final h = HousingModel.fromJson(housingJson(1, rented: true));
      expect(h.isRented, true);
      expect(h.statusLabel, 'Loué');
      expect(h.activeRental!.tenantName, 'Patrick Agossa');
      expect(h.activeRental!.tenantPhone, '0197123456');
    });

    test('bail terminé : le logement n\'est plus loué', () {
      final json = housingJson(1, rented: true);
      (json['active_rental'] as Map)['status'] = 'FINISHED';
      expect(HousingModel.fromJson(json).isRented, false);
    });

    test('clé camelCase activeRental acceptée', () {
      final json = housingJson(1, rented: true);
      json['activeRental'] = json.remove('active_rental');
      expect(HousingModel.fromJson(json).isRented, true);
    });

    test('copyWith(clearActiveRental) libère le logement, sans toucher au code', () {
      final h = HousingModel.fromJson(housingJson(1, rented: true)).copyWith(clearActiveRental: true, rent: 90000);
      expect(h.isRented, false);
      expect(h.rent, 90000);
      expect(h.code, 'CODE-1');
    });

    test('toJson puis fromJson : aller-retour sans perte', () {
      final h = HousingModel.fromJson(housingJson(2, rented: true));
      final again = HousingModel.fromJson(h.toJson());
      expect(again.id, h.id);
      expect(again.rent, h.rent);
      expect(again.activeRental!.tenantName, h.activeRental!.tenantName);
    });

    test('type inconnu -> HOUSE, jour d\'échéance par défaut = 5', () {
      final h = HousingModel.fromJson({'id': 'x', 'type': 'CHÂTEAU'});
      expect(h.type, AccommodationType.HOUSE);
      expect(h.dueDay, 5);
    });
  });

  // ----------------------------------------------------------- Repositories

  group('OwnerDashboardRepository', () {
    late OwnerDashboardRepository repo;
    setUp(() {
      boot();
      repo = OwnerDashboardRepository(OwnerDashboardService(server.client));
    });

    test('dashboard : GET /owner/dashboard', () async {
      server.on('GET', '/owner/dashboard', body: {
        'month': '2026-11', 'expected': 300000, 'received': 100000,
        'late_count': 1, 'tenants_count': 3, 'housings_count': 4,
      });
      final d = await repo.dashboard();
      expect(server.last.path, '/api/owner/dashboard');
      expect(d.percent, 33);
    });

    test('tenants : le serveur renvoie une liste brute, elle est lue', () async {
      server.on('GET', '/owner/tenants', body: [tenantJson('r1', 'LATE'), tenantJson('r2', 'PAID')]);
      final list = await repo.tenants();
      expect(list.map((t) => t.rentalId), ['r1', 'r2']);
      expect(list.first.status, RentStatus.LATE);
    });

    test('tenants : liste vide', () async {
      server.on('GET', '/owner/tenants', body: []);
      expect(await repo.tenants(), isEmpty);
    });

    test('remind : POST /owner/rentals/{id}/remind et message renvoyé', () async {
      server.on('POST', '/owner/rentals/r9/remind', body: {'message': 'Rappel envoyé au locataire.'});
      expect(await repo.remind('r9'), 'Rappel envoyé au locataire.');
      expect(server.last.method, 'POST');
    });

    test('remind : sans message du serveur -> texte par défaut', () async {
      server.on('POST', '/owner/rentals/r9/remind', body: {});
      expect(await repo.remind('r9'), 'Rappel envoyé.');
    });

    test('403 : AppException, pas de plantage', () async {
      server.on('GET', '/owner/dashboard', status: 403, body: {'message': 'Accès refusé.'});
      await expectLater(repo.dashboard(), throwsA(isA<AppException>()));
    });
  });

  group('PropertyRepository', () {
    late PropertyRepository repo;
    setUp(() {
      boot();
      repo = PropertyRepository(PropertyService(server.client), app);
    });

    test('list : lit data et met la liste en cache', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1), housingJson(2, rented: true)]});
      final list = await repo.list();
      expect(list.length, 2);
      expect(list[1].isRented, true);
      expect(app.readJson<List<dynamic>>('owner_housings'), hasLength(2));
    });

    test('list : réseau coupé -> repli sur le cache', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1)]});
      await repo.list();

      server.failWith = const SocketException('unreachable');
      final cached = await repo.list();
      expect(cached.single.id, 'h1');
    });

    test('list : réseau coupé et cache vide -> l\'erreur remonte', () async {
      server.failWith = const SocketException('unreachable');
      await expectLater(repo.list(), throwsA(isA<NetworkException>()));
    });

    test('list : erreur serveur (500) -> pas de repli silencieux', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1)]});
      await repo.list();
      server.on('GET', '/housings', status: 500, body: {'message': 'Boum'});
      await expectLater(repo.list(), throwsA(isA<AppException>()));
    });

    test('detail : GET /housings/{id}', () async {
      server.on('GET', '/housings/h1', body: {'data': housingJson(1, rented: true)});
      final h = await repo.detail('h1');
      expect(h.activeRental!.tenantName, 'Patrick Agossa');
    });

    test('create : envoie le contrat attendu par le back', () async {
      server.on('POST', '/housings', status: 201, body: {'data': housingJson(7)});
      await repo.create(
        title: 'Studio',
        type: AccommodationType.ROOM,
        rent: 45000,
        dueDay: 10,
        city: 'Cotonou',
        district: 'Akpakpa',
      );
      expect(server.last.json, {
        'title': 'Studio',
        'type': 'ROOM',
        'rent': 45000,
        'due_day': 10,
        'city': 'Cotonou',
        'district': 'Akpakpa',
      });
    });

    test('create : 422 -> ValidationException', () async {
      server.on('POST', '/housings', status: 422, body: {
        'message': 'x',
        'errors': {'rent': ['Le loyer doit être d\'au moins 1000.']},
      });
      await expectLater(
        repo.create(title: 'S', type: AccommodationType.ROOM, rent: 5, dueDay: 5, city: 'C', district: 'D'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('update : n\'envoie que les champs fournis', () async {
      server.on('PUT', '/housings/h1', body: {'data': housingJson(1)});
      await repo.update('h1', rent: 120000, dueDay: 8);
      expect(server.last.json, {'rent': 120000, 'due_day': 8});
    });

    test('endRental : POST /rentals/{id}/end', () async {
      server.on('POST', '/rentals/r1/end', body: {'message': 'ok'});
      await repo.endRental('r1');
      expect(server.last.path, '/api/rentals/r1/end');
    });
  });

  // ------------------------------------------------------------ Contrôleurs

  group('OwnerDashboardController (C1/C7)', () {
    late OwnerDashboardController c;
    setUp(() {
      boot();
      c = OwnerDashboardController(
        repository: OwnerDashboardRepository(OwnerDashboardService(server.client)),
        authStorage: MemoryAuthStorage(),
      );
    });

    void stubOk() {
      server.on('GET', '/owner/dashboard', body: {
        'month': '2026-11', 'expected': 400000, 'received': 100000,
        'late_count': 1, 'tenants_count': 4, 'housings_count': 4,
      });
      server.on('GET', '/owner/tenants', body: [
        tenantJson('r1', 'PAID'),
        tenantJson('r2', 'PARTIAL'),
        tenantJson('r3', 'LATE'),
        tenantJson('r4', 'UPCOMING'),
      ]);
    }

    test('load : charge chiffres et locataires', () async {
      stubOk();
      await c.load();
      expect(c.status.value, LoadStatus.loaded);
      expect(c.dashboard.value!.percent, 25);
      expect(c.tenants.length, 4);
    });

    test('toFollow : retards d\'abord, puis partiels, payés exclus', () async {
      stubOk();
      await c.load();
      expect(c.toFollow.map((t) => t.rentalId), ['r3', 'r2']);
      expect(c.lateTenants.map((t) => t.rentalId), ['r3']);
    });

    test('load : erreur serveur -> failure avec message', () async {
      server.on('GET', '/owner/dashboard', status: 500, body: {'message': 'Panne.'});
      await c.load();
      expect(c.status.value, LoadStatus.failure);
      expect(c.errorMessage.value, isNotEmpty);
    });

    test('load : réseau coupé -> failure', () async {
      server.failWith = const SocketException('unreachable');
      await c.load();
      expect(c.status.value, LoadStatus.failure);
    });

    test('load : une relance réussie efface l\'erreur', () async {
      server.failWith = const SocketException('unreachable');
      await c.load();
      server.failWith = null;
      stubOk();
      await c.load();
      expect(c.status.value, LoadStatus.loaded);
      expect(c.errorMessage.value, isNull);
    });
  });

  group('OwnerDashboardController : rappels et navigation', () {
    final navigated = <String>[];
    late OwnerDashboardController c;

    void withApp(String name, Future<void> Function() body) {
      testWidgets(name, (tester) async {
        navigated.clear();
        boot();
        c = OwnerDashboardController(
          repository: OwnerDashboardRepository(OwnerDashboardService(server.client)),
          authStorage: MemoryAuthStorage(),
        );
        await tester.pumpWidget(GetMaterialApp(
          home: const SizedBox(),
          getPages: [
            for (final r in [AppRoutes.ownerDashboard, AppRoutes.ownerProperties, AppRoutes.ownerRents])
              GetPage(name: r, page: () => const SizedBox()),
          ],
          routingCallback: (r) {
            if (r?.current != null) navigated.add(r!.current);
          },
        ));
        await tester.runAsync(body);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpWidget(const SizedBox());
      });
    }

    final tenant = TenantRent.fromJson(tenantJson('r9', 'LATE'));

    withApp('remind : appelle le back et libère le verrou', () async {
      server.on('POST', '/owner/rentals/r9/remind', body: {'message': 'Rappel envoyé au locataire.'});
      await c.remind(tenant);
      expect(server.seen.where((s) => s.path.endsWith('/remind')).length, 1);
      expect(c.isReminding.value, false);
    });

    withApp('remind : échec -> verrou libéré, pas d\'exception', () async {
      server.on('POST', '/owner/rentals/r9/remind', status: 403, body: {'message': 'Accès refusé.'});
      await c.remind(tenant);
      expect(c.isReminding.value, false);
    });

    withApp('remind : double appel simultané ignoré', () async {
      server.on('POST', '/owner/rentals/r9/remind', body: {'message': 'ok'});
      await Future.wait([c.remind(tenant), c.remind(tenant)]);
      expect(server.seen.where((s) => s.path.endsWith('/remind')).length, 1);
    });

    withApp('goToTab : onglets 1 et 2 ouvrent logements et loyers', () async {
      c.goToTab(1);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(navigated, contains(AppRoutes.ownerProperties));
    });
  });

  group('PropertyController (C2/C5/C6)', () {
    late PropertyController c;
    setUp(() {
      boot();
      c = PropertyController(repository: PropertyRepository(PropertyService(server.client), app));
    });

    test('loadHousings : charge et présélectionne le premier logement pour C6', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1), housingJson(2)]});
      await c.loadHousings();
      expect(c.status.value, LoadStatus.loaded);
      expect(c.housings.length, 2);
      expect(c.selectedHousingForTenant.value!.id, 'h1');
    });

    test('loadHousings : ne remplace pas une sélection existante', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1), housingJson(2)]});
      await c.loadHousings();
      c.selectHousingForTenant(c.housings[1]);
      await c.loadHousings();
      expect(c.selectedHousingForTenant.value!.id, 'h2');
    });

    test('loadHousings : aucun logement -> loaded, pas de sélection', () async {
      server.on('GET', '/housings', body: {'data': []});
      await c.loadHousings();
      expect(c.status.value, LoadStatus.loaded);
      expect(c.selectedHousingForTenant.value, isNull);
    });

    test('loadHousings : réseau coupé sans cache -> failure', () async {
      server.failWith = const SocketException('unreachable');
      await c.loadHousings();
      expect(c.status.value, LoadStatus.failure);
      expect(c.errorMessage.value, isNotEmpty);
    });

    test('loadHousings : réseau coupé avec cache -> données du cache', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1)]});
      await c.loadHousings();
      server.failWith = const SocketException('unreachable');
      await c.loadHousings();
      expect(c.status.value, LoadStatus.loaded);
      expect(c.housings.single.id, 'h1');
    });

    test('loadDetail : charge le logement et son locataire', () async {
      server.on('GET', '/housings/h1', body: {'data': housingJson(1, rented: true)});
      await c.loadDetail('h1');
      expect(c.detailStatus.value, LoadStatus.loaded);
      expect(c.selectedHousing.value!.isRented, true);
    });

    test('loadDetail : 403 (logement d\'un autre) -> failure', () async {
      server.on('GET', '/housings/h1', status: 403, body: {'message': 'Accès non autorisé.'});
      await c.loadDetail('h1');
      expect(c.detailStatus.value, LoadStatus.failure);
      expect(c.errorMessage.value, 'Accès non autorisé.');
    });

    test('loadDetail : 404 -> failure', () async {
      await c.loadDetail('inconnu');
      expect(c.detailStatus.value, LoadStatus.failure);
    });
  });

  group('PropertyController : actions avec retour utilisateur', () {
    late PropertyController c;

    void withApp(String name, Future<void> Function() body) {
      testWidgets(name, (tester) async {
        boot();
        c = PropertyController(repository: PropertyRepository(PropertyService(server.client), app));
        await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));
        await tester.runAsync(body);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpWidget(const SizedBox());
      });
    }

    withApp('createHousing : insère en tête, sélectionne, libère le verrou', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1)]});
      await c.loadHousings();
      server.on('POST', '/housings', status: 201, body: {'data': housingJson(5)});

      final created = await c.createHousing(
        title: '  Studio  ',
        type: AccommodationType.ROOM,
        rent: 45000,
        dueDay: 10,
        city: ' Cotonou ',
        district: ' Akpakpa ',
      );

      expect(created!.id, 'h5');
      expect(c.housings.first.id, 'h5');
      expect(c.selectedHousingForTenant.value!.id, 'h5');
      expect(c.isSubmitting.value, false);
      // Les espaces sont retirés avant l'envoi.
      expect(server.last.json['title'], 'Studio');
      expect(server.last.json['city'], 'Cotonou');
    });

    withApp('createHousing : 422 -> null, liste inchangée, verrou libéré', () async {
      server.on('POST', '/housings', status: 422, body: {
        'message': 'x',
        'errors': {'rent': ['Trop bas.']},
      });
      final created = await c.createHousing(
        title: 'S', type: AccommodationType.ROOM, rent: 5, dueDay: 5, city: 'C', district: 'D');
      expect(created, isNull);
      expect(c.housings, isEmpty);
      expect(c.isSubmitting.value, false);
    });

    withApp('createHousing : double soumission ignorée', () async {
      server.on('POST', '/housings', status: 201, body: {'data': housingJson(5)});
      Future<HousingModel?> go() => c.createHousing(
          title: 'S', type: AccommodationType.ROOM, rent: 5000, dueDay: 5, city: 'C', district: 'D');
      await Future.wait([go(), go()]);
      expect(server.seen.where((s) => s.method == 'POST').length, 1);
    });

    withApp('saveTenantLeaseConfig : met à jour la liste, la sélection et le détail', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1), housingJson(2)]});
      await c.loadHousings();
      server.on('GET', '/housings/h1', body: {'data': housingJson(1)});
      await c.loadDetail('h1');
      server.on('PUT', '/housings/h1', body: {'data': {...housingJson(1), 'rent': 175000, 'due_day': 12}});

      final ok = await c.saveTenantLeaseConfig(housingId: 'h1', rent: 175000, dueDay: 12);

      expect(ok, true);
      expect(c.housings.first.rent, 175000);
      expect(c.selectedHousingForTenant.value!.dueDay, 12);
      expect(c.selectedHousing.value!.rent, 175000);
      expect(server.last.json, {'rent': 175000, 'due_day': 12});
    });

    withApp('saveTenantLeaseConfig : refus du serveur -> false, liste intacte', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1)]});
      await c.loadHousings();
      server.on('PUT', '/housings/h1', status: 422, body: {
        'message': 'x',
        'errors': {'due_day': ['Entre 1 et 28.']},
      });
      final ok = await c.saveTenantLeaseConfig(housingId: 'h1', rent: 100000, dueDay: 31);
      expect(ok, false);
      expect(c.housings.first.dueDay, 5);
      expect(c.isSubmitting.value, false);
    });

    withApp('endRental : libère le logement dans la liste et le détail', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1, rented: true)]});
      await c.loadHousings();
      server.on('GET', '/housings/h1', body: {'data': housingJson(1, rented: true)});
      await c.loadDetail('h1');
      server.on('POST', '/rentals/r1/end', body: {'message': 'ok'});

      final ok = await c.endRental(rentalId: 'r1', housingId: 'h1');

      expect(ok, true);
      expect(c.housings.first.isRented, false);
      expect(c.selectedHousing.value!.isRented, false);
    });

    withApp('endRental : erreur -> le logement reste loué', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1, rented: true)]});
      await c.loadHousings();
      server.on('POST', '/rentals/r1/end', status: 403, body: {'message': 'Accès refusé.'});

      final ok = await c.endRental(rentalId: 'r1', housingId: 'h1');

      expect(ok, false);
      expect(c.housings.first.isRented, true);
      expect(c.isSubmitting.value, false);
    });
  });

  // ------------------------------------------------------------ Faux services

  group('Faux services (USE_FAKE_API=true)', () {
    setUp(boot);

    test('FakeOwnerDashboardService : mêmes clés que le vrai contrat', () async {
      final repo = OwnerDashboardRepository(FakeOwnerDashboardService(server.client));
      final d = await repo.dashboard();
      final tenants = await repo.tenants();
      expect(d.expected, greaterThan(0));
      expect(tenants, isNotEmpty);
      expect(tenants.map((t) => t.status).toSet().length, greaterThan(1));
      expect(await repo.remind(tenants.first.rentalId), isNotEmpty);
      expect(server.seen, isEmpty, reason: 'le faux service ne doit faire aucun appel réseau');
    });

    test('FakePropertyService : cycle créer -> lire -> modifier -> clôturer', () async {
      final repo = PropertyRepository(FakePropertyService(server.client), app);
      final before = await repo.list();

      final created = await repo.create(
        title: 'Test', type: AccommodationType.ROOM, rent: 50000, dueDay: 7, city: 'Cotonou', district: 'X');
      expect(created.code, isNotEmpty);
      expect((await repo.list()).length, before.length + 1);

      final updated = await repo.update(created.id, rent: 60000);
      expect(updated.rent, 60000);
      expect((await repo.detail(created.id)).rent, 60000);

      final rented = before.firstWhere((h) => h.isRented);
      await repo.endRental(rented.activeRental!.id);
      expect((await repo.detail(rented.id)).isRented, false);
      expect(server.seen, isEmpty);
    });
  });
}
