import '../services/geolocation_service.dart';
import '../../../domain/models/user_location.dart';

/// Faux service de géolocalisation (`USE_FAKE_API=true`) : position de
/// démonstration à Cotonou, sans GPS ni appel réseau.
class FakeGeolocationService extends GeolocationService {
  FakeGeolocationService({super.client});

  @override
  Future<GeoPoint> currentPosition() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const GeoPoint(6.3703, 2.3912);
  }

  @override
  Future<GeoAddress> reverseGeocode(GeoPoint point) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const GeoAddress(city: 'Cotonou', district: 'Fidjrossè', country: 'Bénin');
  }
}
