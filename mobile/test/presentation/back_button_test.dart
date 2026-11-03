import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/presentation/components/atoms/app_back_button.dart';

Widget page(String name, {String? next}) => Scaffold(
      body: Column(children: [
        Text(name),
        const AppBackButton(),
        if (next != null) TextButton(onPressed: () => Get.toNamed(next), child: Text('vers $next')),
      ]),
    );

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.testMode = true;
  });
  tearDown(Get.reset);

  Future<void> app(WidgetTester tester) => tester.pumpWidget(GetMaterialApp(
        initialRoute: '/a',
        // Vraie transition : pendant l'animation, la page quittée est encore à l'écran et
        // peut recevoir un second appui (c'est le cas réel du double appui).
        defaultTransition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 300),
        getPages: [
          GetPage(name: '/a', page: () => page('A', next: '/b')),
          GetPage(name: '/b', page: () => page('B', next: '/c')),
          GetPage(name: '/c', page: () => page('C')),
        ],
      ));

  testWidgets('un double appui ne dépile qu\'une seule page', (tester) async {
    await app(tester);
    await tester.tap(find.text('vers /b'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('vers /c'));
    await tester.pumpAndSettle();
    expect(find.text('C'), findsOneWidget);

    // deux appuis presque simultanés sur « Retour »
    await tester.tap(find.byType(AppBackButton).first);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(AppBackButton).first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('B'), findsOneWidget, reason: 'on est revenu à B, pas à A');
    expect(find.text('A'), findsNothing);
  });

  testWidgets('sur la première page, « Retour » ne fait rien (pas d\'exception)', (tester) async {
    await app(tester);
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
