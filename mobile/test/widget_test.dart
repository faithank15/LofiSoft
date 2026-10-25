import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app.dart';

void main() {
  testWidgets('E1 affiche le titre et les deux profils', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue. Vous êtes…'), findsOneWidget);
    expect(find.text('Locataire'), findsOneWidget);
    expect(find.text('Propriétaire'), findsOneWidget);
  });
}
