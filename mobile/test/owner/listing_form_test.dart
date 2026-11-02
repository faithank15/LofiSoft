import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/data/remote/fakes/fake_announcement_service.dart';
import 'package:mobile/data/remote/fakes/fake_property_service.dart';
import 'package:mobile/data/remote/fakes/fake_upload_service.dart';
import 'package:mobile/data/remote/services/announcement_service.dart';
import 'package:mobile/data/remote/services/property_service.dart';
import 'package:mobile/data/remote/services/upload_service.dart';
import 'package:mobile/data/repo/owner_announcement_repository.dart';
import 'package:mobile/data/repo/property_repository.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/presentation/components/molecules/photo_picker.dart';
import 'package:mobile/presentation/features/listings/listing_form_controller.dart';
import 'package:mobile/presentation/features/listings/listing_form_page.dart';
import 'package:mobile/presentation/routes/app_routes.dart';
import 'package:mobile/presentation/shared/load_status.dart';

import '../support/fakes.dart';
import 'owner_test.dart' show housingJson;

NewAnnouncement draft({String? housingId = 'h1', String? description}) => NewAnnouncement(
      housingId: housingId,
      title: 'Villa 4 pièces',
      type: AccommodationType.HOUSE,
      rent: 200000,
      depositMonths: 2,
      city: 'Calavi',
      district: 'Togoudo',
      rooms: 4,
      description: description,
    );

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.testMode = true;
  });
  tearDown(Get.reset);

  late FakeServer server;
  late MemoryAppStorage app;
  late Directory tmp;
  late List<String> files;

  setUp(() {
    server = FakeServer();
    app = MemoryAppStorage();
    tmp = Directory.systemTemp.createTempSync('lofi_photos');
    files = [
      for (final n in ['a.jpg', 'b.jpg']) (File('${tmp.path}/$n')..writeAsBytesSync([1, 2, 3])).path,
    ];
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  OwnerAnnouncementRepository repo() =>
      OwnerAnnouncementRepository(AnnouncementService(server.client), UploadService(server.client));

  void stubHappyPath() {
    server.on('POST', '/uploads', status: 201, body: {'url': 'https://res.cloudinary.com/x.jpg'});
    server.on('POST', '/announcements', status: 201, body: {'id': 'a1'});
    server.on('POST', '/announcements/a1/publish', body: {'message': 'ok'});
  }

  group('NewAnnouncement', () {
    test('contrat du back : champs, photos et description nettoyée', () {
      final json = draft(description: '  Quartier calme  ').toJson(['u1', 'u2']);
      expect(json, {
        'housing_id': 'h1',
        'title': 'Villa 4 pièces',
        'type': 'HOUSE',
        'rent': 200000,
        'deposit_months': 2,
        'city': 'Calavi',
        'district': 'Togoudo',
        'rooms': 4,
        'description': 'Quartier calme',
        'photos': ['u1', 'u2'],
      });
    });

    test('sans logement, description vide ni photo : champs omis', () {
      final json = draft(housingId: null, description: '   ').toJson([]);
      expect(json.containsKey('housing_id'), false);
      expect(json.containsKey('description'), false);
      expect(json.containsKey('photos'), false);
    });
  });

  group('OwnerAnnouncementRepository.publish', () {
    test('envoie les photos dans l\'ordre, crée puis publie', () async {
      stubHappyPath();
      final id = await repo().publish(draft(), photoPaths: files);

      expect(id, 'a1');
      expect(server.seen.map((s) => '${s.method} ${s.path}'), [
        'POST /api/uploads',
        'POST /api/uploads',
        'POST /api/announcements',
        'POST /api/announcements/a1/publish',
      ]);
      expect((server.seen[2].json['photos'] as List).length, 2);
    });

    test('sans photo : aucun envoi', () async {
      stubHappyPath();
      await repo().publish(draft());
      expect(server.seen.any((s) => s.path.endsWith('/uploads')), false);
    });

    test('photo refusée (422) : l\'annonce n\'est pas créée', () async {
      server.on('POST', '/uploads', status: 422, body: {
        'message': 'x',
        'errors': {'file': ['Image trop lourde.']},
      });
      await expectLater(repo().publish(draft(), photoPaths: files), throwsA(isA<ValidationException>()));
      expect(server.seen.any((s) => s.path == '/api/announcements'), false);
    });

    test('réponse sans url de photo : erreur claire', () async {
      server.on('POST', '/uploads', status: 201, body: {});
      await expectLater(repo().publish(draft(), photoPaths: files), throwsA(isA<ServerException>()));
    });

    test('création refusée (422) : pas de publication', () async {
      server.on('POST', '/announcements', status: 422, body: {
        'message': 'x',
        'errors': {'rent': ['Trop bas.']},
      });
      await expectLater(repo().publish(draft()), throwsA(isA<ValidationException>()));
      expect(server.seen.any((s) => s.path.endsWith('/publish')), false);
    });

    test('publication refusée : l\'erreur remonte (brouillon gardé côté serveur)', () async {
      server.on('POST', '/announcements', status: 201, body: {'id': 'a1'});
      server.on('POST', '/announcements/a1/publish', status: 409, body: {'message': 'Annulée.'});
      await expectLater(repo().publish(draft()), throwsA(isA<AppException>()));
    });

    test('annonce créée sans identifiant : erreur', () async {
      server.on('POST', '/announcements', status: 201, body: {});
      await expectLater(repo().publish(draft()), throwsA(isA<ServerException>()));
    });
  });

  group('ListingFormController', () {
    ListingFormController build() => ListingFormController(
          repository: repo(),
          properties: PropertyRepository(PropertyService(server.client), app),
        );

    test('caution en mois : arrondie, jamais négative', () {
      expect(ListingFormController.depositMonths(rent: 200000, deposit: 400000), 2);
      expect(ListingFormController.depositMonths(rent: 200000, deposit: 500000), 3);
      expect(ListingFormController.depositMonths(rent: 200000, deposit: 0), 0);
      expect(ListingFormController.depositMonths(rent: 0, deposit: 400000), 0);
    });

    testWidgets('l\'annonce reprend le logement choisi : titre et type', (tester) async {
      server.on('GET', '/housings', body: {'data': [housingJson(1), {...housingJson(2), 'type': 'ROOM'}]});
      server.on('POST', '/uploads', status: 201, body: {'url': 'https://x.test/p.jpg'});
      server.on('POST', '/announcements', status: 201, body: {'id': 'a1'});
      server.on('POST', '/announcements/a1/publish', body: {'message': 'ok'});
      await tester.pumpWidget(GetMaterialApp(
        home: const SizedBox(),
        defaultTransition: Transition.noTransition,
        getPages: [GetPage(name: AppRoutes.ownerDashboard, page: () => const SizedBox())],
      ));
      final c = build();
      await tester.runAsync(() async {
        await c.loadHousings();
        c.selectHousing(c.housings[1]);
        await c.publish(city: 'X', district: 'Y', rent: 200000, deposit: 0);
      });
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpWidget(const SizedBox());
      final body = server.seen.firstWhere((s) => s.path == '/api/announcements').json;
      expect(body['housing_id'], 'h2');
      expect(body['title'], 'Logement 2');
      expect(body['type'], 'ROOM');
    });

    testWidgets('sans logement choisi : refus, aucun appel réseau', (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));
      final c = build();
      late bool ok;
      await tester.runAsync(() async {
        ok = await c.publish(city: 'C', district: 'D', rent: 200000, deposit: 0);
      });
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(ok, false);
      expect(server.seen, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    test('loadHousings : présélectionne le premier ; hors connexion le formulaire reste utilisable', () async {
      server.on('GET', '/housings', body: {'data': [housingJson(1), housingJson(2)]});
      final c = build();
      await c.loadHousings();
      expect(c.housing.value!.id, 'h1');

      final offline = ListingFormController(
        repository: repo(),
        properties: PropertyRepository(PropertyService(server.client), MemoryAppStorage()),
      );
      server.failWith = const SocketException('unreachable');
      await offline.loadHousings();
      expect(offline.housings, isEmpty);
      expect(offline.housing.value, isNull);
      expect(offline.housingsStatus.value, LoadStatus.failure);
    });

    test('retrait de photo : hors limites ignoré', () {
      final c = build()..photos.addAll(const [PhotoItem(localPath: 'a'), PhotoItem(localPath: 'b')]);
      c.removePhoto(5);
      c.removePhoto(-1);
      expect(c.photos.length, 2);
      c.removePhoto(0);
      expect(c.photos.single.localPath, 'b');
    });

    test('retour : de l\'étape 2 vers 1', () {
      final c = build()..goToStep(1);
      c.back();
      expect(c.step.value, 0);
    });

    testWidgets('publish : succès -> true, retour à l\'accueil, verrou libéré', (tester) async {
      stubHappyPath();
      server.on('GET', '/housings', body: {'data': [housingJson(1)]});
      final routes = <String>[];
      await tester.pumpWidget(GetMaterialApp(
        home: const SizedBox(),
        defaultTransition: Transition.noTransition,
        getPages: [GetPage(name: AppRoutes.ownerDashboard, page: () => const SizedBox())],
        routingCallback: (r) {
          if (r?.current != null) routes.add(r!.current);
        },
      ));
      final c = build();
      late bool ok;
      await tester.runAsync(() async {
        await c.loadHousings();
        c.selectRooms(3);
        ok = await c.publish(city: ' Calavi ', district: 'Togoudo', rent: 200000, deposit: 400000, description: 'Calme');
      });
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(ok, true);
      expect(c.isSubmitting.value, false);
      expect(routes, contains(AppRoutes.ownerDashboard));
      final body = server.seen.firstWhere((s) => s.path == '/api/announcements').json;
      expect(body['housing_id'], 'h1');
      expect(body['title'], 'Logement 1');
      expect(body['city'], 'Calavi');
      expect(body['rooms'], 3);
      expect(body['deposit_months'], 2);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('publish : échec -> false, on reste sur le formulaire, verrou libéré', (tester) async {
      server.on('POST', '/announcements', status: 422, body: {
        'message': 'x',
        'errors': {'rent': ['Le loyer doit être d\'au moins 1000.']},
      });
      await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));
      final c = build();
      late bool ok;
      await tester.runAsync(() async {
        ok = await c.publish(city: 'C', district: 'D', rent: 5, deposit: 0);
      });
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(ok, false);
      expect(c.isSubmitting.value, false);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ListingFormPage (C3 -> C4)', () {
    Future<ListingFormController> open(WidgetTester tester) async {
      server.on('GET', '/housings', body: {'data': [housingJson(1)]});
      final c = ListingFormController(
        repository: repo(),
        properties: PropertyRepository(PropertyService(server.client), app),
      );
      Get.put(c);
      await tester.binding.setSurfaceSize(const Size(420, 900));
      await tester.pumpWidget(GetMaterialApp(
        home: const ListingFormPage(),
        defaultTransition: Transition.noTransition,
        getPages: [GetPage(name: AppRoutes.ownerDashboard, page: () => const SizedBox())],
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      return c;
    }

    testWidgets('étape 1 : logement présélectionné, ville et quartier préremplis', (tester) async {
      await open(tester);
      expect(find.text('Étape 1 sur 2'), findsOneWidget);
      expect(find.text('Logement 1'), findsOneWidget);
      expect(find.text('Cotonou'), findsOneWidget);
      expect(find.text('Fidjrossè'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('étape 1 : ville et quartier viennent du logement, non modifiables', (tester) async {
      await open(tester);
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.every((f) => f.enabled == false), true);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('aucun logement : pas de formulaire, un bouton pour en ajouter un', (tester) async {
      server.on('GET', '/housings', body: {'data': []});
      final c = ListingFormController(
        repository: repo(),
        properties: PropertyRepository(PropertyService(server.client), app),
      );
      Get.put(c);
      await tester.binding.setSurfaceSize(const Size(420, 900));
      await tester.pumpWidget(GetMaterialApp(
        home: const ListingFormPage(),
        defaultTransition: Transition.noTransition,
        getPages: [GetPage(name: AppRoutes.ownerHousingCreate, page: () => const SizedBox())],
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      expect(find.text('Aucun logement'), findsOneWidget);
      expect(find.text('Ajouter un logement'), findsOneWidget);
      expect(find.text('Continuer'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('étape 2 : loyer vide ou trop bas refusé, rien n\'est envoyé', (tester) async {
      final c = await open(tester);
      await tester.tap(find.text('Continuer'));
      await tester.pump();
      expect(c.step.value, 1);
      expect(find.text('Étape 2 sur 2'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.tap(find.text('Publier l’annonce'));
      await tester.pump();
      expect(find.text('Indiquez le loyer.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '500');
      await tester.tap(find.text('Publier l’annonce'));
      await tester.pump();
      expect(find.textContaining('au moins 1 000 FCFA'), findsOneWidget);
      expect(server.seen.where((s) => s.method == 'POST'), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('parcours complet : étape 1, étape 2, publication', (tester) async {
      stubHappyPath();
      final c = await open(tester);
      await tester.tap(find.text('Continuer'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, '200000');
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      expect(c.rooms.value, 4);

      await tester.tap(find.text('Publier l’annonce'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      final body = server.seen.firstWhere((s) => s.path == '/api/announcements').json;
      expect(body['rent'], 200000);
      expect(body['rooms'], 4);
      expect(server.seen.last.path, '/api/announcements/a1/publish');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('retour depuis l\'étape 2 : revient à l\'étape 1 sans quitter', (tester) async {
      final c = await open(tester);
      await tester.tap(find.text('Continuer'));
      await tester.pump();
      c.back();
      await tester.pump();
      expect(find.text('Étape 1 sur 2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Faux services (USE_FAKE_API=true)', () {
    test('publication complète sans aucun appel réseau', () async {
      final r = OwnerAnnouncementRepository(
        FakeAnnouncementService(server.client),
        FakeUploadService(server.client),
      );
      final id = await r.publish(draft(), photoPaths: files);
      expect(id, startsWith('fake-'));
      expect(server.seen, isEmpty);

      final props = PropertyRepository(FakePropertyService(server.client), app);
      expect(await props.list(), isNotEmpty);
    });
  });
}
