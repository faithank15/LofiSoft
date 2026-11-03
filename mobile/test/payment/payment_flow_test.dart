import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/data/cache/app_storage.dart';
import 'package:mobile/data/cache/auth_storage.dart';
import 'package:mobile/data/remote/api_client.dart';
import 'package:mobile/presentation/components/molecules/amount_field.dart';
import 'package:mobile/presentation/features/payment/payment_binding.dart';
import 'package:mobile/presentation/features/payment/payment_checkout_page.dart';
import 'package:mobile/presentation/features/payment/receipt_details_page.dart';
import 'package:mobile/presentation/routes/app_routes.dart';

import '../support/fakes.dart';
import 'payment_pages_test.dart' show situationActive, rentSummary;

/// Parcours réel B3 -> B4 avec les VRAIS bindings et routes.
/// Régression vue sur téléphone : après le paiement, B4 affichait « Aucun paiement à afficher »,
/// car la route de succès ne transportait pas l'identifiant et GetX recrée le contrôleur (état perdu).
void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('après un paiement réussi, B4 affiche le paiement (pas l\'état vide)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    final server = FakeServer();
    Get.put<AuthStorage>(server.auth);
    Get.put<AppStorage>(MemoryAppStorage());
    Get.put<ApiClient>(server.client);

    server.on('GET', '/me/situation', body: situationActive);
    server.on('GET', '/me/rent', body: rentSummary());
    server.on('GET', '/me/payments', body: {'data': []});
    server.on('POST', '/payments', status: 201, body: {
      'payment': {'id': 'p1', 'status': 'PENDING', 'amount': 20000, 'operator': 'MTN'},
    });
    server.on('GET', '/payments/p1', body: {
      'id': 'p1', 'status': 'SUCCESS', 'amount': 20000, 'operator': 'MTN', 'phone': '0196000011',
    });
    server.on('GET', '/payments/p1/receipt', body: {
      'reference': 'RC-20261104-ABCD', 'amount': 20000, 'operator': 'MTN Mobile Money',
      'housing': 'Appartement 1A', 'period': '2026-11', 'paid_at': '2026-11-04T10:00:00.000000Z',
    });

    await tester.pumpWidget(GetMaterialApp(
      initialRoute: AppRoutes.payment,
      defaultTransition: Transition.noTransition,
      transitionDuration: Duration.zero,
      getPages: [
        GetPage(name: AppRoutes.payment, page: () => const PaymentCheckoutPage(), binding: PaymentBinding()),
        GetPage(name: AppRoutes.paymentSuccess, page: () => const ReceiptDetailsPage(), binding: PaymentBinding()),
        GetPage(name: AppRoutes.rentTracking, page: () => const SizedBox()),
      ],
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump();

    await tester.enterText(find.byType(AmountField).first, '20000');
    await tester.enterText(find.byType(TextField).last, '0196000011');
    await tester.pump();
    await tester.tap(find.text('Payer').last);
    await tester.pump();
    // le contrôleur attend 2 s (horloge simulée du test) entre deux lectures de l'état du paiement
    await tester.pump(const Duration(seconds: 3));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(Get.currentRoute, startsWith(AppRoutes.paymentSuccess));
    expect(find.text('Aucun paiement à afficher'), findsNothing, reason: 'B4 doit montrer le paiement réussi');
    expect(find.textContaining('20\u00A0000'), findsWidgets);
  });
}
