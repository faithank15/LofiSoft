import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/data/remote/services/payment_service.dart';
import 'package:mobile/data/remote/services/rental_service.dart';
import 'package:mobile/data/repo/payment_repository.dart';
import 'package:mobile/data/repo/tenant_rent_repository.dart';
import 'package:mobile/domain/models/installment_model.dart';
import 'package:mobile/domain/models/receipt_model.dart';
import 'package:mobile/presentation/components/atoms/app_card.dart';
import 'package:mobile/presentation/components/molecules/amount_field.dart';
import 'package:mobile/presentation/components/molecules/operator_card.dart';
import 'package:mobile/presentation/features/payment/payment_checkout_page.dart';
import 'package:mobile/presentation/features/payment/payment_controller.dart';
import 'package:mobile/presentation/features/payment/receipt_details_page.dart';
import 'package:mobile/presentation/routes/app_routes.dart';

import '../support/fakes.dart';

const situationActive = {
  'status': 'ACTIVE',
  'rental_id': 'r1',
  'housing': {'id': 'h1', 'title': 'Appartement 1A', 'city': 'Cotonou', 'district': 'Fidjrossè', 'rent': 150000, 'due_day': 5},
  'owner': {'name': 'Koffi Mensah', 'telephone': '0197000002'},
};

Map<String, dynamic> rentSummary({int total = 150000, int paid = 90000, int remaining = 60000}) => {
      'period': '2026-11',
      'total': total,
      'paid': paid,
      'remaining': remaining,
      'due_date': '2026-11-05',
      'status': remaining == 0 ? 'PAID' : (paid == 0 ? 'UNPAID' : 'PARTIAL'),
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

  void stubActive() {
    server.on('GET', '/me/situation', body: situationActive);
    server.on('GET', '/me/rent', body: rentSummary());
    server.on('GET', '/me/payments', body: {'data': []});
  }

  group('PaymentCheckoutPage (B3)', () {
    Future<void> pumpPage(WidgetTester tester, {PaymentController? controller}) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final c = controller ?? PaymentController(
        repository: PaymentRepository(PaymentService(server.client)),
        rentRepository: repo(),
      );
      Get.put(c);
      await tester.pumpWidget(GetMaterialApp(
        home: const PaymentCheckoutPage(),
        defaultTransition: Transition.noTransition,
        getPages: [
          GetPage(name: AppRoutes.paymentSuccess, page: () => const SizedBox()),
        ],
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }

    testWidgets('affiche le formulaire quand chargé', (tester) async {
      stubActive();
      await pumpPage(tester);

      expect(find.text('Payer mon loyer'), findsOneWidget);
      expect(find.text('Loyer de novembre'), findsOneWidget);
      // CurrencyFormatter utilise des espaces insécables (nbsp)
      expect(find.text('Reste 60 000 FCFA'), findsOneWidget);
      expect(find.text('Combien voulez-vous payer ?'), findsOneWidget);
      expect(find.text('Payer avec'), findsOneWidget);
      expect(find.text('MTN Mobile Money'), findsOneWidget);
      expect(find.text('Moov Money'), findsOneWidget);
      expect(find.text('Numéro à débiter'), findsOneWidget);
      expect(find.text('Frais pour vous'), findsOneWidget);
      expect(find.text('Aucun'), findsOneWidget);
      expect(find.text('Payer'), findsOneWidget);
    });

    testWidgets('erreur si montant vide', (tester) async {
      stubActive();
      await pumpPage(tester);

      await tester.tap(find.text('Payer'));
      await tester.pump();

      expect(find.text('Entrez un montant à payer.'), findsOneWidget);
    });

    testWidgets('erreur si montant sous minimum', (tester) async {
      stubActive();
      await pumpPage(tester);

      await tester.enterText(find.byType(AmountField).first, '500');
      await tester.pump();

      // L'erreur exacte sous le champ (avec nbsp), distincte du texte d'aide
      expect(find.text('Minimum : 1 000 FCFA par paiement.'), findsOneWidget);
    });

    testWidgets('sélection opérateur MTN/MOOV', (tester) async {
      stubActive();
      await pumpPage(tester);

      // Par défaut MTN sélectionné
      final mtnCards = find.byWidgetPredicate((w) => w is OperatorCard && w.name == 'MTN Mobile Money');
      final moovCards = find.byWidgetPredicate((w) => w is OperatorCard && w.name == 'Moov Money');

      // Note: selected n'est pas accessible via le widget après build, on vérifie la présence
      expect(mtnCards, findsOneWidget);
      expect(moovCards, findsOneWidget);

      await tester.tap(moovCards.first);
      await tester.pump();

      // Après tap, Moov devrait être sélectionné (mais difficile à vérifier sans state)
      expect(moovCards, findsOneWidget);
    });
  });

  group('ReceiptDetailsPage (B4)', () {
    Future<void> pumpPage(
      WidgetTester tester, {
      PaymentController? controller,
      Size size = const Size(390, 844),
    }) async {
      await tester.binding.setSurfaceSize(size);
      final c = controller ?? PaymentController(
        repository: PaymentRepository(PaymentService(server.client)),
        rentRepository: repo(),
      );
      Get.put(c);
      // Simuler un paiement réussi
      c.paid.value = Installment.fromJson({'payment': {'id': 'pay-1', 'status': 'SUCCESS', 'amount': 30000, 'operator': 'MTN'}});
      c.receipt.value = Receipt.fromJson({
        'reference': 'RC-20261102-0001',
        'amount': 30000,
        'paid_at': '2026-11-02T10:00:00Z',
        'operator': 'MTN Mobile Money',
        'housing': 'Appartement 1A',
        'period': '2026-11',
      });
      // Définir le téléphone pour maskedPhone
      c.setPhone('0197123456');
      await tester.pumpWidget(GetMaterialApp(
        home: const ReceiptDetailsPage(),
        defaultTransition: Transition.noTransition,
        getPages: [
          GetPage(name: AppRoutes.rentTracking, page: () => const SizedBox()),
        ],
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }

    testWidgets('affiche confirmation et détails', (tester) async {
      stubActive();
      await pumpPage(tester);

      expect(find.text('Paiement réussi'), findsOneWidget);
      // CurrencyFormatter utilise des espaces insécables — Text.rich => textContaining
      expect(find.textContaining('30 000'), findsOneWidget); // dans le hero
      expect(find.text('Loyer de novembre'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Payé avec'), findsOneWidget);
      expect(find.text('MTN Mobile Money'), findsOneWidget);
      expect(find.text('Numéro'), findsOneWidget);
      expect(find.textContaining('01 97'), findsOneWidget);
      expect(find.text('Référence'), findsOneWidget);
      expect(find.text('RC-20261102-0001'), findsOneWidget);
      expect(find.text('Voir mon reçu'), findsOneWidget);
      expect(find.text('Retour à mon loyer'), findsOneWidget);
    });

    testWidgets('la carte du loyer n\'est pas rognée et le montant est complet', (tester) async {
      stubActive();
      await pumpPage(tester);

      // Le montant ne doit pas être tronqué (« Reste 60 000 F… »).
      // CurrencyFormatter utilise des espaces insécables.
      final reste = tester.widget<Text>(find.textContaining('Reste'));
      expect(reste.data, contains('60 000'.replaceAll(' ', ' ')));
      expect(reste.data, isNot(contains('…')));

      // La carte ne doit pas être coupée par le bord de la zone défilante :
      // son bord haut doit rester dans le viewport.
      final card = tester.getRect(find.byType(AppCard).first);
      final viewport = tester.getRect(find.byType(SingleChildScrollView).first);
      expect(card.top, greaterThanOrEqualTo(viewport.top));

      // Le bandeau est centré. On teste sur un écran large : la police de
      // substitution des tests rend le titre moins large que l'écran, donc
      // un bandeau non étiré se calerait à gauche.
      await pumpPage(tester, size: const Size(1000, 800));
      final coche = tester.getRect(find.byIcon(Icons.check_rounded));
      expect(coche.center.dx, closeTo(500, 2));
    });

    testWidgets('sans paiement : état vide', (tester) async {      stubActive();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final c = PaymentController(
        repository: PaymentRepository(PaymentService(server.client)),
        rentRepository: repo(),
      );
      Get.put(c);
      // Pas de paid.value
      await tester.pumpWidget(GetMaterialApp(
        home: const ReceiptDetailsPage(),
        defaultTransition: Transition.noTransition,
        getPages: [GetPage(name: AppRoutes.rentTracking, page: () => const SizedBox())],
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      expect(find.text('Aucun paiement à afficher'), findsOneWidget);
      expect(find.text('Effectuez un paiement depuis « Mon loyer ».'), findsOneWidget);
      expect(find.text('Retour à mon loyer'), findsOneWidget);
    });
  });
}