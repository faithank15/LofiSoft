/// Configuration injectée à la compilation, jamais écrite en dur.
///
/// Lancer l'app avec :
///   flutter run --dart-define=API_BASE_URL=https://votre-api.onrender.com/api
/// Sans paramètre, on vise le serveur Laravel local vu depuis l'émulateur Android
/// (10.0.2.2 = le PC hôte).
///
/// TANT QUE L'API N'EXISTE PAS, lancer avec de fausses réponses :
///   flutter run --dart-define=USE_FAKE_API=true
abstract final class AppConfig {
  /// Par défaut : le back de ce PC, via `adb reverse tcp:8000 tcp:8000` (téléphone en USB ou émulateur).
  /// Autre serveur : `--dart-define=API_BASE_URL=http://<adresse>:8000/api`.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const _timeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 20,
  );

  static const timeout = Duration(seconds: _timeoutSeconds);

  /// `true` : l'authentification répond avec de fausses données (développement sans serveur).
  /// Désactivé par défaut : en production, aucun faux comportement n'est actif.
  static const useFakeApi = bool.fromEnvironment('USE_FAKE_API');

  /// Clé de l'API Google Geocoding (facultative).
  ///
  /// Sans clé, le géocodage inverse utilise **OpenStreetMap / Nominatim**,
  /// gratuit et sans clé. Pour basculer sur Google :
  ///   flutter run --dart-define=GOOGLE_GEOCODING_API_KEY=AIza...
  static const googleGeocodingApiKey = String.fromEnvironment('GOOGLE_GEOCODING_API_KEY');

  /// Base du géocodage inverse gratuit (OpenStreetMap).
  static const nominatimBaseUrl = String.fromEnvironment(
    'NOMINATIM_BASE_URL',
    defaultValue: 'https://nominatim.openstreetmap.org',
  );

  /// Base de l'API Google Geocoding.
  static const googleGeocodingBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Nominatim exige un `User-Agent` identifiable (politique d'usage).
  static const geolocationUserAgent = String.fromEnvironment(
    'GEOLOCATION_USER_AGENT',
    defaultValue: 'LofiSoft/1.0 (https://github.com/faithank15/LofiSoft)',
  );
}
