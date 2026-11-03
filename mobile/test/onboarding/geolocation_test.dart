import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/data/remote/fakes/fake_geolocation_service.dart';
import 'package:mobile/data/remote/services/geolocation_service.dart';
import 'package:mobile/data/repo/geolocation_repository.dart';
import 'package:mobile/domain/constants/benin_locations.dart';
import 'package:mobile/domain/models/user_location.dart';
import 'package:mobile/presentation/features/onboarding/ville_controller.dart';

/// Géolocalisation : rapprochement des noms renvoyés par l'API et pré-sélection
/// dans l'onboarding locataire.
void main() {
  group('BeninLocations', () {
    test('matchCity : insensible à la casse et aux accents', () {
      expect(BeninLocations.matchCity('Cotonou'), 'Cotonou');
      expect(BeninLocations.matchCity('cotonou'), 'Cotonou');
      expect(BeninLocations.matchCity('Abomey Calavi'), 'Abomey-Calavi');
      expect(BeninLocations.matchCity('Commune de Cotonou'), 'Cotonou');
    });

    test('matchCity : ville inconnue -> null', () {
      expect(BeninLocations.matchCity('Paris'), isNull);
      expect(BeninLocations.matchCity(''), isNull);
    });

    test('matchNeighborhood : quartier connu de la ville', () {
      expect(BeninLocations.matchNeighborhood('Cotonou', 'Fidjrossè'), 'Fidjrossè');
      expect(BeninLocations.matchNeighborhood('Cotonou', 'fidjrosse'), 'Fidjrossè');
      expect(BeninLocations.matchNeighborhood('Cotonou', 'Akpakpa'), 'Akpakpa');
    });

    test('matchNeighborhood : quartier d\'une autre ville -> null', () {
      expect(BeninLocations.matchNeighborhood('Cotonou', 'Akassato'), isNull);
      expect(BeninLocations.matchNeighborhood('Cotonou', ''), isNull);
    });

    test('les listes de villes et quartiers restent celles de la maquette', () {
      expect(BeninLocations.cities.first, 'Cotonou');
      expect(BeninLocations.neighborhoodsByCity['Cotonou'], contains('Fidjrossè'));
      expect(BeninLocations.neighborhoodsByCity['Autre ville'], isEmpty);
    });
  });

  group('VilleController — position', () {
    test('position reconnue : ville et quartier présélectionnés', () async {
      final controller = VilleController(
        geolocationRepository: GeolocationRepository(FakeGeolocationService()),
      );

      await controller.useMyLocation();

      expect(controller.locating.value, isFalse);
      expect(controller.locationMessage.value, isNull);
      expect(controller.selectedCity.value, 'Cotonou');
      expect(controller.chosenNeighborhoods, contains('Fidjrossè'));
      expect(controller.location.value, isNotNull);
      expect(controller.location.value!.city, 'Cotonou');
    });

    test('position hors liste : message, sélection inchangée', () async {
      final controller = VilleController(
        geolocationRepository: GeolocationRepository(
          _StubService(
            const UserLocation(
              point: GeoPoint(48.8566, 2.3522),
              city: 'Paris',
              district: 'Le Marais',
            ),
          ),
        ),
      );

      await controller.useMyLocation();

      expect(controller.locationMessage.value, contains('Paris'));
      expect(controller.selectedCity.value, 'Cotonou');
      expect(controller.chosenNeighborhoods, isNot(contains('Le Marais')));
    });

    test('quartier inconnu : la ville est retenue, quartier à choisir', () async {
      final controller = VilleController(
        geolocationRepository: GeolocationRepository(
          _StubService(
            const UserLocation(
              point: GeoPoint(6.3703, 2.3912),
              city: 'Cotonou',
              district: 'Quartier Inconnu',
            ),
          ),
        ),
      );

      await controller.useMyLocation();

      expect(controller.selectedCity.value, 'Cotonou');
      expect(controller.chosenNeighborhoods, isEmpty);
      expect(controller.locationMessage.value, contains('Quartier non reconnu'));
    });

    test('erreur du service : message affiché, pas de crash', () async {
      final controller = VilleController(
        geolocationRepository: GeolocationRepository(_FailingService()),
      );

      await controller.useMyLocation();

      expect(controller.locating.value, isFalse);
      expect(controller.locationMessage.value, isNotNull);
      expect(controller.selectedCity.value, 'Cotonou');
    });
  });
}

/// Service de test : position imposée, sans GPS ni réseau.
class _StubService extends GeolocationService {
  _StubService(this._location);

  final UserLocation _location;

  @override
  Future<GeoPoint> currentPosition() async => _location.point;

  @override
  Future<GeoAddress> reverseGeocode(GeoPoint point) async =>
      GeoAddress(city: _location.city, district: _location.district);
}

/// Service de test : échoue comme un refus de permission.
class _FailingService extends GeolocationService {
  @override
  Future<GeoPoint> currentPosition() async =>
      throw const ValidationException('Autorisez la localisation pour utiliser votre position.');
}
