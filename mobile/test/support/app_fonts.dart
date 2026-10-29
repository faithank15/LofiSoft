import 'package:flutter/services.dart';

/// Charge la vraie police Plus Jakarta Sans dans le moteur de test.
///
/// Sans cela, `flutter test` rend chaque glyphe avec une largeur égale à
/// `fontSize` (police de test), ce qui produit de faux débordements : un texte
/// de 20 caractères à 16 px occupe 320 px au lieu de ~150 px. Avec la vraie
/// police, les assertions de débordement deviennent fiables.
Future<void> loadAppFonts() async {
  final loader = FontLoader('PlusJakartaSans');
  const assets = <String>[
    'assets/fonts/PlusJakartaSans-Regular.ttf',
    'assets/fonts/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/PlusJakartaSans-Bold.ttf',
    'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
  ];
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
