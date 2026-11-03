import '../../domain/models/user_location.dart';
import '../remote/services/geolocation_service.dart';

/// Position de l'utilisateur : GPS puis géocodage inverse.
///
/// Le contrôleur reçoit une [UserLocation] complète (coordonnées + ville +
/// quartier) et n'a à gérer qu'un seul appel.
class GeolocationRepository {
  GeolocationRepository(this._service);

  final GeolocationService _service;

  /// Position actuelle, lisible et exploitable par l'application.
  Future<UserLocation> locate() async {
    final point = await _service.currentPosition();
    final address = await _service.reverseGeocode(point);
    return UserLocation(
      point: point,
      city: address.city,
      district: address.district,
    );
  }
}
