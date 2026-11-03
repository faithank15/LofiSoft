import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/json_utils.dart';
import '../../../domain/models/user_location.dart';

/// Position de l'utilisateur et géocodage inverse.
///
/// - La position vient du GPS du téléphone (plugin `geolocator`) : aucune clé,
///   aucun compte, la permission est demandée à l'utilisateur.
/// - Le géocodage inverse (position -> ville, quartier) utilise par défaut
///   **OpenStreetMap / Nominatim**, gratuit et sans clé. Une clé Google
///   (`--dart-define=GOOGLE_GEOCODING_API_KEY=...`) permet de basculer sur
///   l'API Google Geocoding.
class GeolocationService extends GetxService {
  GeolocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Position GPS actuelle. Demande la permission si elle n'est pas accordée.
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ValidationException('Activez la localisation sur votre téléphone.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ValidationException('Localisation bloquée : autorisez-la dans les réglages.');
    }
    if (permission == LocationPermission.denied) {
      throw const ValidationException('Autorisez la localisation pour utiliser votre position.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } on TimeoutException {
      throw const NetworkException('La position n\'a pas pu être déterminée à temps.');
    } on SocketException {
      throw const NetworkException();
    }
  }

  /// Géocodage inverse : position -> ville, quartier.
  Future<GeoAddress> reverseGeocode(GeoPoint point) async {
    if (AppConfig.googleGeocodingApiKey.isNotEmpty) {
      return _google(point);
    }
    return _nominatim(point);
  }

  /// OpenStreetMap — gratuit, sans clé. Un `User-Agent` identifiable est
  /// exigé par la politique d'usage de Nominatim.
  Future<GeoAddress> _nominatim(GeoPoint point) async {
    final uri = Uri.parse('${AppConfig.nominatimBaseUrl}/reverse').replace(
      queryParameters: {
        'format': 'jsonv2',
        'lat': '${point.latitude}',
        'lon': '${point.longitude}',
        'zoom': '16',
        'addressdetails': '1',
      },
    );

    final response = await _client.get(uri, headers: {
      'User-Agent': AppConfig.geolocationUserAgent,
      'Accept': 'application/json',
    }).timeout(AppConfig.timeout);

    if (response.statusCode != 200) {
      throw const ServerException('Impossible de lire votre position.');
    }

    final body = asJsonMap(jsonDecode(utf8.decode(response.bodyBytes)));
    final address = asJsonMap(body['address']);
    return GeoAddress(
      city: _first(address, const [
        'city',
        'town',
        'village',
        'municipality',
        'county',
        'state_district',
      ]),
      district: _first(address, const [
        'suburb',
        'city_district',
        'neighbourhood',
        'quarter',
        'district',
        'residential',
      ]),
      country: _first(address, const ['country']),
    );
  }

  /// Google Geocoding — utilisé quand une clé est fournie à la compilation.
  Future<GeoAddress> _google(GeoPoint point) async {
    final uri = Uri.parse(AppConfig.googleGeocodingBaseUrl).replace(
      queryParameters: {
        'lat': '${point.latitude}',
        'lon': '${point.longitude}',
        'language': 'fr',
        'key': AppConfig.googleGeocodingApiKey,
      },
    );

    final response = await _client.get(uri, headers: {
      'Accept': 'application/json',
    }).timeout(AppConfig.timeout);

    if (response.statusCode != 200) {
      throw const ServerException('Impossible de lire votre position.');
    }

    final body = asJsonMap(jsonDecode(utf8.decode(response.bodyBytes)));
    if (body['status'] != 'OK') {
      throw const ServerException('Position introuvable par le géocodeur.');
    }
    final results = asJsonList(body['results']);
    if (results.isEmpty) {
      throw const ServerException('Position introuvable par le géocodeur.');
    }
    final components = asJsonList(asJsonMap(results.first)['address_components']);

    String? byType(List<String> types) {
      for (final component in components) {
        final map = asJsonMap(component);
        final found = asJsonList(map['types']).map((t) => '$t').toList();
        if (found.any(types.contains)) return '${map['long_name'] ?? ''}';
      }
      return null;
    }

    return GeoAddress(
      city: byType(const ['locality', 'postal_town', 'administrative_area_level_2']) ?? '',
      district: byType(const ['sublocality', 'neighborhood', 'administrative_area_level_3']) ?? '',
      country: byType(const ['country']) ?? '',
    );
  }

  /// Première valeur non vide parmi les clés testées.
  String _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
