/// Position GPS : latitude et longitude.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  String toString() => '($latitude, $longitude)';
}

/// Ce que l'API de géocodage inverse dit de la position : une ville, un
/// quartier, un pays — les noms sont libres (accentuation et libellés varient
/// selon l'API), d'où [BeninLocations.matchCity] pour les rapprocher de la
/// liste proposée à l'utilisateur.
class GeoAddress {
  const GeoAddress({
    required this.city,
    this.district = '',
    this.country = '',
  });

  final String city;
  final String district;
  final String country;

  /// « Fidjrossè, Cotonou »
  String get label => district.isEmpty ? city : '$district, $city';
}

/// Position de l'utilisateur, exploitable par l'application.
class UserLocation {
  const UserLocation({
    required this.point,
    required this.city,
    this.district = '',
  });

  final GeoPoint point;
  final String city;
  final String district;

  /// « Fidjrossè, Cotonou »
  String get label => district.isEmpty ? city : '$district, $city';
}
