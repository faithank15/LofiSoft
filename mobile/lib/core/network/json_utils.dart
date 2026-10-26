/// Conversions sûres de données JSON dynamiques.

/// Renvoie une Map<String, dynamic>, ou une Map vide si la valeur n'en est pas une.
Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

/// Renvoie une liste, ou une liste vide si la valeur n'en est pas une.
List<dynamic> asJsonList(Object? value) => value is List ? value : <dynamic>[];
