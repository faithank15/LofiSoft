/// Villes et quartiers proposés à l'onboarding locataire (Bénin).
///
/// La liste est volontairement courte : elle sert de filtres de recherche.
/// Le géocodage inverse renvoie des noms libres (« Commune de Cotonou »,
/// « Fidjrosse ») : `matchCity` et `matchNeighborhood` les rapprochent de
/// cette liste, en ignorant la casse et les accents.
abstract final class BeninLocations {
  /// Villes proposées.
  static const cities = <String>[
    'Cotonou',
    'Abomey-Calavi',
    'Porto-Novo',
    'Parakou',
    'Autre ville',
  ];

  /// Quartiers disponibles par ville.
  static const neighborhoodsByCity = <String, List<String>>{
    'Cotonou': ['Fidjrossè', 'Haie Vive', 'Akpakpa', 'Cadjèhoun', 'Agla', 'Godomey'],
    'Abomey-Calavi': ['Godomey', 'Akassato', 'Zinvié', 'Ouèdo', 'Gbazaké'],
    'Porto-Novo': ['Hogbonou', 'Missérété', 'Agoungbo', 'Djrin'],
    'Parakou': ['Centre', 'Peulh', 'Zongo', 'Banikanni', 'Koupéla'],
    'Autre ville': [],
  };

  /// Minuscules, sans accents ni ponctuation : pour comparer deux noms.
  static String normalize(String value) {
    const accents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
    const plain = 'aaaaaaceeeeiiiinooooouuuuyy';
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = accents.indexOf(char);
      buffer.write(index >= 0 ? plain[index] : char);
    }
    return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Ville connue correspondant à un nom libre (« cotonou » -> « Cotonou »).
  static String? matchCity(String raw) {
    final key = normalize(raw);
    if (key.isEmpty) return null;
    for (final city in cities) {
      if (city == 'Autre ville') continue;
      if (normalize(city) == key) return city;
    }
    // Correspondance partielle : « Commune de Cotonou », « Cotonou 2 »…
    if (key.length < 4) return null;
    for (final city in cities) {
      if (city == 'Autre ville') continue;
      final cityKey = normalize(city);
      if (key.contains(cityKey) || cityKey.contains(key)) return city;
    }
    return null;
  }

  /// Quartier connu d'une ville correspondant à un nom libre.
  static String? matchNeighborhood(String city, String raw) {
    final key = normalize(raw);
    if (key.isEmpty) return null;
    final list = neighborhoodsByCity[city] ?? const <String>[];
    for (final neighborhood in list) {
      if (normalize(neighborhood) == key) return neighborhood;
    }
    if (key.length < 4) return null;
    for (final neighborhood in list) {
      final neighborhoodKey = normalize(neighborhood);
      if (key.contains(neighborhoodKey) || neighborhoodKey.contains(key)) return neighborhood;
    }
    return null;
  }
}
