import '../../core/utils/json_utils.dart';

/// Critères choisis par le locataire pendant l'onboarding (E2, E3, E4).
/// Conservés sur le téléphone ; ils servent de filtres par défaut au fil d'annonces.
class SearchPreferences {
  const SearchPreferences({
    this.city = '',
    this.neighborhoods = const [],
    this.types = const [],
    this.budgetLabel = '',
    this.minPrice,
    this.maxPrice,
  });

  final String city;
  final List<String> neighborhoods;

  /// Libellés choisis à l'écran E3 (Chambre, Studio, Appartement, Maison).
  final List<String> types;
  final String budgetLabel;
  final int? minPrice;
  final int? maxPrice;

  bool get isEmpty => city.isEmpty && types.isEmpty && minPrice == null && maxPrice == null;

  /// Valeur du filtre `type` de l'API, seulement si les choix n'en désignent qu'un.
  String? get apiType {
    final values = types.map(_apiTypeOf).toSet();
    return values.length == 1 ? values.first : null;
  }

  static String _apiTypeOf(String label) => switch (label) {
        'Chambre' || 'Studio' => 'ROOM',
        'Appartement' || 'Maison' => 'HOUSE',
        _ => 'OTHER',
      };

  /// Tranche de budget de l'écran E4 -> (minimum, maximum) en FCFA.
  static (int?, int?) rangeOf(String label) => switch (label) {
        'Moins de 100 000 FCFA' => (null, 100000),
        '100 000 à 300 000 FCFA' => (100000, 300000),
        '300 000 à 500 000 FCFA' => (300000, 500000),
        'Plus de 500 000 FCFA' => (500000, null),
        _ => (null, null),
      };

  SearchPreferences copyWith({
    String? city,
    List<String>? neighborhoods,
    List<String>? types,
    String? budgetLabel,
  }) {
    final label = budgetLabel ?? this.budgetLabel;
    final (min, max) = budgetLabel == null ? (minPrice, maxPrice) : rangeOf(label);
    return SearchPreferences(
      city: city ?? this.city,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      types: types ?? this.types,
      budgetLabel: label,
      minPrice: min,
      maxPrice: max,
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'neighborhoods': neighborhoods,
        'types': types,
        'budgetLabel': budgetLabel,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
      };

  factory SearchPreferences.fromJson(Map<String, dynamic> json) => SearchPreferences(
        city: '${json['city'] ?? ''}',
        neighborhoods: asJsonList(json['neighborhoods']).whereType<String>().toList(),
        types: asJsonList(json['types']).whereType<String>().toList(),
        budgetLabel: '${json['budgetLabel'] ?? ''}',
        minPrice: _intOrNull(json['minPrice']),
        maxPrice: _intOrNull(json['maxPrice']),
      );

  static int? _intOrNull(Object? v) => v is num ? v.toInt() : null;
}
