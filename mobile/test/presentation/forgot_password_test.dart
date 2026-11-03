import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/data/remote/services/auth_service.dart';
import 'package:mobile/data/repo/auth_repository.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/domain/models/user_model.dart';
import 'package:mobile/presentation/features/auth/forgot_password_controller.dart';
import 'package:mobile/presentation/shared/load_status.dart';

import '../support/fakes.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  late FakeServer server;
  late ForgotPasswordController c;

  void boot() {
    server = FakeServer();
    c = ForgotPasswordController(repository: AuthRepository(AuthService(server.client), server.auth));
  }

  test('succès : POST /auth/forgot-password, état « envoyé »', () async {
    boot();
    server.on('POST', '/auth/forgot-password', body: {'message': 'ok'});
    await c.send('  patrick@lofi.bj ');
    expect(server.last.path, '/api/auth/forgot-password');
    expect(server.last.json, {'email': 'patrick@lofi.bj'});
    expect(c.sent.value, true);
    expect(c.status.value, LoadStatus.loaded);
    expect(c.errorMessage.value, isNull);
  });

  test('erreur serveur : pas d\'état « envoyé », message affichable', () async {
    boot();
    server.on('POST', '/auth/forgot-password', status: 422, body: {
      'message': 'Adresse invalide.',
      'errors': {'email': ['Adresse invalide.']},
    });
    await c.send('x');
    expect(c.sent.value, false);
    expect(c.status.value, LoadStatus.failure);
    expect(c.errorMessage.value, 'Adresse invalide.');
  });

  test('réseau coupé : message « Pas de connexion internet. »', () async {
    boot();
    server.onRaw('POST', '/auth/forgot-password', (_) async => throw const SocketLikeError());
    await c.send('a@b.bj');
    expect(c.sent.value, false);
    expect(c.errorMessage.value, isNotNull);
  });

  test('double appui : une seule requête', () async {
    boot();
    server.on('POST', '/auth/forgot-password', body: {'message': 'ok'});
    await Future.wait([c.send('a@b.bj'), c.send('a@b.bj')]);
    expect(server.seen.where((r) => r.path.endsWith('/auth/forgot-password')).length, 1);
  });

  test('ne touche PAS à la session : un utilisateur connecté le reste (régression)', () async {
    boot();
    await server.auth.saveSession(
      token: 't',
      user: const UserModel(id: '1', nom: 'N', prenoms: 'P', email: 'p@lofi.bj', telephone: '0197000000', role: UserRole.TENANT),
    );
    server.on('POST', '/auth/forgot-password', body: {'message': 'ok'});
    await c.send('p@lofi.bj');
    expect(server.auth.hasSession, true);
    expect(server.seen.any((r) => r.path.endsWith('/auth/logout')), false);
  });
}

class SocketLikeError implements Exception {
  const SocketLikeError();
}
