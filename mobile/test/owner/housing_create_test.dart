import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/data/remote/services/property_service.dart';
import 'package:mobile/data/repo/property_repository.dart';
import 'package:mobile/presentation/features/owner_properties/housing_create_page.dart';
import 'package:mobile/presentation/features/owner_properties/property_controller.dart';
import 'package:mobile/presentation/routes/app_routes.dart';

import '../support/fakes.dart';
import 'owner_test.dart' show housingJson;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.testMode = true;
  });
  tearDown(Get.reset);

  late FakeServer server;
  late List<String> routes;

  Future<PropertyController> open(WidgetTester tester) async {
    server = FakeServer();
    routes = [];
    server.on('GET', '/housings', body: {'data': []});
    final c = PropertyController(repository: PropertyRepository(PropertyService(server.client), MemoryAppStorage()));
    Get.put(c);
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    await tester.pumpWidget(GetMaterialApp(
      home: const HousingCreatePage(),
      defaultTransition: Transition.noTransition,
      getPages: [GetPage(name: AppRoutes.ownerPropertyDetail, page: () => const SizedBox())],
      routingCallback: (r) {
        if (r?.current != null) routes.add(r!.current);
      },
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
    return c;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('formulaire vide : messages, rien n\'est envoyé', (tester) async {
    await open(tester);
    await tester.tap(find.text('Enregistrer le logement'));
    await tester.pump();

    expect(find.text('Indiquez le loyer.'), findsOneWidget);
    expect(server.seen.where((s) => s.method == 'POST'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('jour d\'échéance hors 1-28 refusé', (tester) async {
    await open(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Studio');
    await tester.enterText(fields.at(1), '60000');
    await tester.enterText(fields.at(2), '31');
    await tester.enterText(fields.at(3), 'Cotonou');
    await tester.enterText(fields.at(4), 'Akpakpa');
    await tester.tap(find.text('Enregistrer le logement'));
    await tester.pump();

    expect(find.text('Entre 1 et 28.'), findsOneWidget);
    expect(server.seen.where((s) => s.method == 'POST'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('loyer trop bas refusé', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).at(1), '500');
    await tester.tap(find.text('Enregistrer le logement'));
    await tester.pump();
    expect(find.textContaining('au moins 1 000 FCFA'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('création : envoi du bon contrat, puis détail du logement (code à partager)', (tester) async {
    await open(tester);
    server.on('POST', '/housings', status: 201, body: {'data': housingJson(7)});

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), ' Studio ');
    await tester.enterText(fields.at(1), '60000');
    await tester.enterText(fields.at(2), '10');
    await tester.enterText(fields.at(3), 'Cotonou');
    await tester.enterText(fields.at(4), 'Akpakpa');
    await tester.tap(find.text('Chambre'));
    await tester.pump();
    await tester.tap(find.text('Enregistrer le logement'));
    await settle(tester);

    expect(server.last.json, {
      'title': 'Studio',
      'type': 'ROOM',
      'rent': 60000,
      'due_day': 10,
      'city': 'Cotonou',
      'district': 'Akpakpa',
    });
    expect(routes.last, '/owner/properties/detail/h7');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('refus du serveur (422) : on reste sur le formulaire', (tester) async {
    await open(tester);
    server.on('POST', '/housings', status: 422, body: {
      'message': 'x',
      'errors': {'rent': ['Trop bas.']},
    });
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Studio');
    await tester.enterText(fields.at(1), '60000');
    await tester.enterText(fields.at(3), 'Cotonou');
    await tester.enterText(fields.at(4), 'Akpakpa');
    await tester.tap(find.text('Enregistrer le logement'));
    await settle(tester);

    expect(routes.where((r) => r.contains('detail')), isEmpty);
    expect(find.text('Enregistrer le logement'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
