import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/app_config.dart';
import 'package:mobile/core/errors/app_exception.dart';

import 'package:mobile/domain/models/user_model.dart';

import '../support/fakes.dart';

UserModel _user() => UserModel.fromJson(userJson);

void main() {
  late FakeServer server;
  setUp(() => server = FakeServer());

  test('GET : URL de base, en-têtes JSON, pas de jeton sans session', () async {
    server.on('GET', '/health', body: {'ok': true});
    final res = await server.client.get('/health');

    expect(res['ok'], true);
    expect(server.last.request.url.toString(), startsWith(AppConfig.apiBaseUrl));
    expect(server.last.request.headers['Accept'], 'application/json');
    expect(server.last.request.headers.containsKey('Authorization'), false);
  });

  test('ajoute le jeton Bearer quand une session existe', () async {
    await server.auth.saveSession(token: 'tok123', user: _user());
    server.on('GET', '/auth/me');
    await server.client.get('/auth/me');

    expect(server.last.request.headers['Authorization'], 'Bearer tok123');
  });

  test('transmet les paramètres de requête et ignore une query vide', () async {
    server.on('GET', '/announcements');
    await server.client.get('/announcements', query: {'city': 'Abomey-Calavi', 'page': '2'});
    expect(server.last.query, {'city': 'Abomey-Calavi', 'page': '2'});

    await server.client.get('/announcements', query: {});
    expect(server.last.request.url.hasQuery, false);
  });

  test('POST/PUT envoient du JSON, DELETE aucun corps', () async {
    server.on('POST', '/auth/login');
    server.on('PUT', '/x');
    server.on('DELETE', '/x');
    await server.client.post('/auth/login', body: {'email': 'a@b.c'});
    expect(server.last.json, {'email': 'a@b.c'});
    expect(server.last.request.headers['Content-Type'], contains('application/json'));

    await server.client.put('/x', body: {'a': 1});
    expect(server.last.method, 'PUT');
    await server.client.delete('/x');
    expect(server.last.method, 'DELETE');
    expect(server.last.body, isEmpty);
  });

  test('un corps vide (204) ne plante pas : `data` vaut null', () async {
    server.on('POST', '/auth/logout', status: 204, body: '');
    expect((await server.client.post('/auth/logout'))['data'], isNull);
  });

  test('un corps liste est rangé sous `data`', () async {
    server.on('GET', '/list', body: [1, 2, 3]);
    expect((await server.client.get('/list'))['data'], [1, 2, 3]);
  });

  group('erreurs', () {
    test('401 AVEC jeton : session effacée + UnauthorizedException', () async {
      await server.auth.saveSession(token: 'old', user: _user());
      server.on('GET', '/auth/me', status: 401, body: {'message': 'Authentification requise.'});

      await expectLater(server.client.get('/auth/me'), throwsA(isA<UnauthorizedException>()));
      expect(server.auth.hasSession, false);
    });

    test('401 SANS jeton (mauvais mot de passe) : garde le message du serveur', () async {
      server.on('POST', '/auth/login', status: 401, body: {'message': 'Email ou mot de passe incorrect.'});

      await expectLater(
        server.client.post('/auth/login', body: {}),
        throwsA(isA<UnauthorizedException>().having((e) => e.message, 'message', 'Email ou mot de passe incorrect.')),
      );
    });

    test('401 sans jeton ni message : texte par défaut', () async {
      server.on('POST', '/auth/login', status: 401, body: {});
      await expectLater(
        server.client.post('/auth/login'),
        throwsA(isA<UnauthorizedException>().having((e) => e.message, 'message', contains('incorrect'))),
      );
    });

    test('422 : première erreur de champ du format Laravel', () async {
      server.on('POST', '/auth/register', status: 422, body: {
        'message': 'Le champ nom est obligatoire. (et 1 autre erreur)',
        'errors': {
          'nom': ['Le champ nom est obligatoire.'],
          'email': ['Cette adresse e-mail est déjà prise.'],
        },
      });

      await expectLater(
        server.client.post('/auth/register'),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'Le champ nom est obligatoire.')),
      );
    });

    test('422 sans `errors` : repli sur `message`', () async {
      server.on('POST', '/payments', status: 422, body: {'message': 'Le montant dépasse le solde.'});
      await expectLater(
        server.client.post('/payments'),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'Le montant dépasse le solde.')),
      );
    });

    test('422 sans rien : message générique', () async {
      server.on('POST', '/x', status: 422, body: {});
      await expectLater(server.client.post('/x'), throwsA(isA<ValidationException>()));
    });

    test('409 et 404 : ServerException avec le message du serveur', () async {
      server.on('POST', '/rentals/join', status: 409, body: {'message': 'Vous avez déjà une location active ou en attente.'});
      await expectLater(
        server.client.post('/rentals/join'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', contains('déjà une location'))),
      );
      // route inconnue du faux serveur -> 404 JSON
      await expectLater(
        server.client.get('/nope'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', 'Ressource introuvable.')),
      );
    });

    test('403 : ServerException avec le message du serveur', () async {
      server.on('GET', '/admin/users', status: 403, body: {'message': 'Accès réservé aux administrateurs.'});
      await expectLater(
        server.client.get('/admin/users'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', contains('administrateurs'))),
      );
    });

    test('500 : message générique, jamais le détail serveur', () async {
      server.on('GET', '/x', status: 500, body: {'message': 'SQLSTATE[42S02] secret'});
      await expectLater(
        server.client.get('/x'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', isNot(contains('SQLSTATE')))),
      );
    });

    test('réponse HTML (page d\'erreur) : pas de plantage de décodage', () async {
      server.on('GET', '/x', status: 502, body: '<html>Bad gateway</html>');
      await expectLater(server.client.get('/x'), throwsA(isA<ServerException>()));
    });

    test('coupure réseau : NetworkException', () async {
      server.failWith = const SocketException('Network is unreachable');
      await expectLater(server.client.get('/x'), throwsA(isA<NetworkException>()));
    });

    test('ClientException : NetworkException', () async {
      server.failWith = http.ClientException('boom');
      await expectLater(server.client.get('/x'), throwsA(isA<NetworkException>()));
    });

    test('délai dépassé : NetworkException avec message dédié', () {
      fakeAsync((async) {
        server.onRaw('GET', '/slow', (_) => Completer<http.Response>().future);
        Object? error;
        server.client.get('/slow').catchError((Object e) {
          error = e;
          return <String, dynamic>{};
        });
        async.elapse(AppConfig.timeout + const Duration(seconds: 1));
        expect(error, isA<NetworkException>());
        expect((error! as NetworkException).message, contains('trop de temps'));
      });
    });
  });

  test('upload : multipart avec jeton, champs texte et fichier', () async {
    await server.auth.saveSession(token: 'tok', user: _user());
    server.on('POST', '/uploads', status: 201, body: {'url': 'https://x.test/a.jpg'});
    final file = File('${Directory.systemTemp.path}/lofi_upload_test.jpg')..writeAsBytesSync([1, 2, 3]);
    addTearDown(file.deleteSync);

    final res = await server.client.upload('/uploads', filePath: file.path, fields: {'kind': 'identity_id'});

    expect(res['url'], 'https://x.test/a.jpg');
    expect(server.last.request.headers['Content-Type'], startsWith('multipart/form-data'));
    expect(server.last.request.headers['Authorization'], 'Bearer tok');
    expect(server.last.body, contains('name="kind"'));
    expect(server.last.body, contains('identity_id'));
    expect(server.last.body, contains('name="file"'));
  });

  test('upload 422 : message de validation remonté', () async {
    server.on('POST', '/uploads', status: 422, body: {
      'errors': {'file': ['Le champ image doit être une image.']},
    });
    final file = File('${Directory.systemTemp.path}/lofi_upload_test2.txt')..writeAsStringSync('x');
    addTearDown(file.deleteSync);

    await expectLater(
      server.client.upload('/uploads', filePath: file.path),
      throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('image'))),
    );
  });
}


