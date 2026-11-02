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
  static const _uriPart = "10.140.106.79";
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://$_uriPart:8000/api',
  );

  static const _timeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 20,
  );

  static const timeout = Duration(seconds: _timeoutSeconds);

  /// `true` : l'authentification répond avec de fausses données (développement sans serveur).
  /// Désactivé par défaut : en production, aucun faux comportement n'est actif.
  static const useFakeApi = bool.fromEnvironment('USE_FAKE_API');
}
