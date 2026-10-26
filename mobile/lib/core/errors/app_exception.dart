/// Exceptions applicatives : les couches basses les lèvent, les contrôleurs les attrapent
/// et affichent `message` à l'utilisateur (jamais une erreur brute).
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Pas de connexion internet.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expirée. Reconnectez-vous.']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Certaines informations sont invalides.']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Le serveur a rencontré un problème.']);
}
