import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile/di/injector.dart';
import 'package:mobile/presentation/routes/app_pages.dart';
import 'package:mobile/presentation/routes/app_routes.dart';

import 'support/app_fonts.dart';

/// Captures d'écran des écrans d'onboarding (390 × 844), générées avec :
///   flutter test --update-goldens test/onboarding_goldens_test.dart
/// puis lues à la main pour vérifier le rendu visuel.
/// Les images de référence dépendent de la plateforme (rendu des polices) : elles ne
/// concordent qu'avec la machine qui les a générées. Comparaison à la demande :
///   RUN_GOLDENS=1 flutter test test/onboarding_goldens_test.dart
final Object _skipUnlessRequested = Platform.environment['RUN_GOLDENS'] == null
    ? 'Captures dépendantes de la plateforme : RUN_GOLDENS=1 pour les comparer'
    : false;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('lofisoft_goldens');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
            case 'getTemporaryDirectory':
            case 'getLibraryDirectory':
              return tempDir.path;
          }
          return null;
        });
    await GetStorage.init();
    await loadAppFonts();
  });

  tearDownAll(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // Ignoré : dossier temporaire du système.
    }
  });

  setUp(() async {
    Get.testMode = true;
    await initializeDependencies();
  });

  tearDown(Get.reset);

  Future<void> pumpRoute(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: AppPages.pages,
        initialRoute: route,
      ),
    );
    await tester.pumpAndSettle();
  }

  const ecrans = <String, String>{
    'E1_bienvenue': AppRoutes.onboarding,
    'E2_ville': AppRoutes.onboardingVille,
    'E3_type': AppRoutes.onboardingType,
    'E4_budget': AppRoutes.onboardingBudget,
    'E5_proprio_bienvenue': AppRoutes.onboardingProprietaire,
  };

  for (final entree in ecrans.entries) {
    testWidgets('capture ${entree.key}', skip: _skipUnlessRequested != false, (tester) async {
      await pumpRoute(tester, entree.value);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(GetMaterialApp),
        matchesGoldenFile('goldens/${entree.key}.png'),
      );
    });
  }

  testWidgets('capture E6 et E7 (étapes suivantes du parcours proprio)',
      skip: _skipUnlessRequested != false, (tester) async {
    await pumpRoute(tester, AppRoutes.onboardingProprietaire);

    // E5 -> E6
    await tester.drag(find.byType(PageView), const Offset(-390, 0));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GetMaterialApp),
      matchesGoldenFile('goldens/E6_proprio_etapes.png'),
    );

    // E6 -> E7
    await tester.drag(find.byType(PageView), const Offset(-390, 0));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GetMaterialApp),
      matchesGoldenFile('goldens/E7_proprio_badge.png'),
    );
  });
}
