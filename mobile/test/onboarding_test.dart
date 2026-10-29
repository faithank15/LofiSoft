import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile/di/injector.dart';
import 'package:mobile/presentation/routes/app_pages.dart';
import 'package:mobile/presentation/routes/app_routes.dart';

import 'support/app_fonts.dart';

/// Tests du parcours d'onboarding : câblage des routes et tenue du layout.
///
/// Chaque écran est pompé au format d'un téléphone (390 × 844). Un
/// débordement de layout (RenderFlex) fait échouer le test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('lofisoft_onboarding');
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
    // Vraie police : sinon les largeurs de texte sont fausses et les tests
    // de débordement signalent de faux positifs.
    await loadAppFonts();
  });

  tearDownAll(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // Ignoré : le dossier est dans le répertoire temporaire du système.
    }
  });

  setUp(() async {
    Get.testMode = true;
    await initializeDependencies();
  });

  tearDown(Get.reset);

  /// Pompe l'écran de la [route] et renvoie le [WidgetTester] prêt à interagir.
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
    'E1 · Bienvenue (profil)': AppRoutes.onboarding,
    'E2 · Locataire — ville': AppRoutes.onboardingVille,
    'E3 · Locataire — type': AppRoutes.onboardingType,
    'E4 · Locataire — budget': AppRoutes.onboardingBudget,
    'E5 à E7 · Propriétaire': AppRoutes.onboardingProprietaire,
  };

  for (final entree in ecrans.entries) {
    testWidgets('${entree.key} s\'affiche sans débordement', (tester) async {
      await pumpRoute(tester, entree.value);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('E1 propose le parcours locataire et le parcours propriétaire',
      (tester) async {
    await pumpRoute(tester, AppRoutes.onboarding);

    expect(find.text('Locataire'), findsOneWidget);
    expect(find.text('Propriétaire'), findsOneWidget);

    await tester.tap(find.text('Locataire'));
    await tester.pumpAndSettle();

    expect(find.text('Où voulez-vous habiter ?'), findsOneWidget);
  });

  testWidgets('E1 envoie le propriétaire vers le parcours E5 → E7',
      (tester) async {
    await pumpRoute(tester, AppRoutes.onboarding);

    await tester.tap(find.text('Propriétaire'));
    await tester.pumpAndSettle();

    expect(find.text('Tous vos loyers, d’un coup d’œil.'), findsOneWidget);
  });

  testWidgets('le parcours locataire E1 → E4 se termine sur le catalogue',
      (tester) async {
    await pumpRoute(tester, AppRoutes.onboarding);

    // E1 -> E2
    await tester.tap(find.text('Locataire'));
    await tester.pumpAndSettle();
    expect(find.text('Où voulez-vous habiter ?'), findsOneWidget);

    // E2 -> E3
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Quel type de logement ?'), findsOneWidget);

    // E3 -> E4
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Votre budget par mois ?'), findsOneWidget);

    // E4 -> catalogue des annonces
    await tester.tap(find.text('Voir mes logements'));
    await tester.pumpAndSettle();
    expect(find.text('Annonces'), findsOneWidget);
  });

  testWidgets('« Passer » quitte le parcours locataire', (tester) async {
    await pumpRoute(tester, AppRoutes.onboardingVille);

    expect(find.text('Passer'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(find.text('Annonces'), findsOneWidget);
  });
}
