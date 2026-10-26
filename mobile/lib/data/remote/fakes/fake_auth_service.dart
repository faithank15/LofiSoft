import '../../../core/errors/app_exception.dart';
import '../../../domain/models/enums.dart';
import '../services/auth_service.dart';

/// FAUX service d'authentification, pour développer l'interface sans API.
/// Actif uniquement avec `--dart-define=USE_FAKE_API=true` (voir AuthBinding).
/// Le repository, lui, reste le vrai : il ne contient aucune donnée simulée.
///
/// Comptes de test (mot de passe `Test1234`) :
///   locataire@lofi.bj   -> TENANT
///   proprio@lofi.bj     -> OWNER
///   admin@lofi.bj       -> ADMIN
/// Toute autre adresse est refusée. L'inscription accepte tout, sauf `deja@lofi.bj`
/// (pour tester l'erreur « adresse déjà utilisée »).
class FakeAuthService extends AuthService {
  FakeAuthService(super.api);

  static const _password = 'Test1234';
  static const _delay = Duration(milliseconds: 900);

  static const _accounts = <String, (UserRole, String, String)>{
    'locataire@lofi.bj': (UserRole.TENANT, 'Patrick', 'Agossa'),
    'proprio@lofi.bj': (UserRole.OWNER, 'Koffi', 'Mensah'),
    'admin@lofi.bj': (UserRole.ADMIN, 'Awa', 'Sanni'),
  };

  @override
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    await Future<void>.delayed(_delay);
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || password != _password) {
      throw const UnauthorizedException('E-mail ou mot de passe incorrect.');
    }
    return _session(
      id: email,
      role: account.$1,
      prenoms: account.$2,
      nom: account.$3,
      email: email,
      telephone: '0197123456',
    );
  }

  @override
  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    required String password,
    required UserRole role,
  }) async {
    await Future<void>.delayed(_delay);
    if (email.trim().toLowerCase() == 'deja@lofi.bj') {
      throw const ValidationException('Cette adresse e-mail est déjà utilisée.');
    }
    return _session(
      id: email,
      role: role,
      prenoms: prenoms,
      nom: nom,
      email: email,
      telephone: telephone,
    );
  }

  @override
  Future<Map<String, dynamic>> me() async => throw const UnauthorizedException();

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    await Future<void>.delayed(_delay);
    return <String, dynamic>{'message': 'ok'};
  }

  Map<String, dynamic> _session({
    required String id,
    required UserRole role,
    required String prenoms,
    required String nom,
    required String email,
    required String telephone,
  }) =>
      <String, dynamic>{
        'token': 'fake-token-${role.name.toLowerCase()}',
        'user': <String, dynamic>{
          'id': id,
          'nom': nom,
          'prenoms': prenoms,
          'email': email,
          'telephone': telephone,
          'role': role.name,
          'actif': true,
        },
      };
}
