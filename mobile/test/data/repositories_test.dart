import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/data/remote/services/announcement_service.dart';
import 'package:mobile/data/remote/services/auth_service.dart';
import 'package:mobile/data/remote/services/rental_service.dart';
import 'package:mobile/data/remote/services/upload_service.dart';
import 'package:mobile/data/repo/announcement_repository.dart';
import 'package:mobile/data/repo/auth_repository.dart';
import 'package:mobile/data/repo/identity_repository.dart';
import 'package:mobile/data/repo/rental_repository.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/domain/models/user_model.dart';

import '../support/fakes.dart';

void main() {
  late FakeServer server;
  late MemoryAuthStorage storage;
  setUp(() {
    storage = MemoryAuthStorage();
    server = FakeServer(storage: storage);
  });

  group('AuthRepository', () {
    late AuthRepository repo;
    setUp(() => repo = AuthRepository(AuthService(server.client), storage));

    test('login : appelle /auth/login, enregistre jeton et profil', () async {
      server.on('POST', '/auth/login', body: {'token': 'tok', 'user': userJson});

      final user = await repo.login(email: 'patrick@lofi.bj', password: 'Test1234');

      expect(server.last.json, {'email': 'patrick@lofi.bj', 'password': 'Test1234'});
      expect(user.role, UserRole.TENANT);
      expect(storage.token, 'tok');
      expect(storage.hasSession, true);
    });

    test('login : réponse sans jeton -> ServerException, aucune session', () async {
      server.on('POST', '/auth/login', body: {'user': userJson});
      await expectLater(repo.login(email: 'a@b.c', password: 'x'), throwsA(isA<ServerException>()));
      expect(storage.hasSession, false);
    });

    test('login : jeton sous data.access_token accepté', () async {
      server.on('POST', '/auth/login', body: {'data': {'access_token': 'abc', 'user': userJson}});
      await repo.login(email: 'a@b.c', password: 'x');
      expect(storage.token, 'abc');
    });

    test('login : mauvais identifiants -> message du serveur, pas de session', () async {
      server.on('POST', '/auth/login', status: 401, body: {'message': 'Email ou mot de passe incorrect.'});
      await expectLater(
        repo.login(email: 'a@b.c', password: 'x'),
        throwsA(isA<UnauthorizedException>().having((e) => e.message, 'm', 'Email ou mot de passe incorrect.')),
      );
      expect(storage.hasSession, false);
    });

    test('login : compte suspendu (403) -> message du serveur', () async {
      server.on('POST', '/auth/login', status: 403, body: {'message': 'Ce compte a été suspendu.'});
      await expectLater(
        repo.login(email: 'a@b.c', password: 'x'),
        throwsA(isA<ServerException>().having((e) => e.message, 'm', 'Ce compte a été suspendu.')),
      );
    });

    test('register : sépare prénoms/nom, envoie le rôle, ouvre la session', () async {
      server.on('POST', '/auth/register', status: 201, body: {'token': 't', 'user': {...userJson, 'role': 'OWNER'}});

      final user = await repo.register(
        fullName: 'Jean Pierre Agossa',
        email: 'j@lofi.bj',
        phone: '0197123456',
        password: 'Test1234',
        role: UserRole.OWNER,
      );

      expect(server.last.json['prenoms'], 'Jean Pierre');
      expect(server.last.json['nom'], 'Agossa');
      expect(server.last.json['telephone'], '0197123456');
      expect(server.last.json['role'], 'OWNER');
      expect(user.role, UserRole.OWNER);
      expect(storage.hasSession, true);
    });

    test('register : un seul mot -> nom seul', () async {
      server.on('POST', '/auth/register', status: 201, body: {'token': 't', 'user': userJson});
      await repo.register(fullName: 'Agossa', email: 'j@lofi.bj', phone: '0197123456', password: 'Test1234', role: UserRole.TENANT);
      expect(server.last.json['nom'], 'Agossa');
      expect(server.last.json['prenoms'], '');
    });

    test('register : sans jeton dans la réponse, enchaîne avec login', () async {
      server.on('POST', '/auth/register', status: 201, body: {'user': userJson});
      server.on('POST', '/auth/login', body: {'token': 'tok', 'user': userJson});

      await repo.register(fullName: 'A B', email: 'a@b.co', phone: '0197123456', password: 'Test1234', role: UserRole.TENANT);

      expect(server.seen.map((s) => s.path), ['/api/auth/register', '/api/auth/login']);
      expect(storage.token, 'tok');
    });

    test('register : e-mail déjà pris (422) -> message de champ, rien de stocké', () async {
      server.on('POST', '/auth/register', status: 422, body: {
        'message': 'x',
        'errors': {'email': ['Cette adresse e-mail est déjà prise.']},
      });
      await expectLater(
        repo.register(fullName: 'A B', email: 'a@b.co', phone: '0197123456', password: 'Test1234', role: UserRole.TENANT),
        throwsA(isA<ValidationException>().having((e) => e.message, 'm', 'Cette adresse e-mail est déjà prise.')),
      );
      expect(storage.hasSession, false);
    });

    group('refreshSession', () {
      test('sans session : null, aucun appel réseau', () async {
        expect(await repo.refreshSession(), isNull);
        expect(server.seen, isEmpty);
      });

      test('jeton valide : met le profil à jour (ex. rôle modifié côté serveur)', () async {
        await storage.saveSession(token: 'tok', user: _user('TENANT'));
        server.on('GET', '/auth/me', body: {'user': {...userJson, 'role': 'OWNER'}});

        final user = await repo.refreshSession();

        expect(user!.role, UserRole.OWNER);
        expect(storage.role, UserRole.OWNER);
        expect(storage.token, 'tok');
      });

      test('401 : session effacée, null', () async {
        await storage.saveSession(token: 'old', user: _user('TENANT'));
        server.on('GET', '/auth/me', status: 401, body: {});

        expect(await repo.refreshSession(), isNull);
        expect(storage.hasSession, false);
      });

      test('compte suspendu (le back répond 401) : déconnexion, pas de session fantôme', () async {
        await storage.saveSession(token: 'tok', user: _user('TENANT'));
        server.on('GET', '/auth/me', status: 401, body: {'message': 'Ce compte a été suspendu.'});

        expect(await repo.refreshSession(), isNull);
        expect(storage.hasSession, false);
      });

      test('réseau coupé : on garde la session en cache', () async {
        await storage.saveSession(token: 'tok', user: _user('OWNER'));
        server.failWith = const SocketException('down');

        final user = await repo.refreshSession();

        expect(user!.role, UserRole.OWNER);
        expect(storage.hasSession, true);
      });

      test('erreur 500 : on garde la session en cache', () async {
        await storage.saveSession(token: 'tok', user: _user('TENANT'));
        server.on('GET', '/auth/me', status: 500, body: {});
        expect(await repo.refreshSession(), isNotNull);
        expect(storage.hasSession, true);
      });
    });

    group('logout', () {
      test('révoque le jeton côté serveur puis efface la session', () async {
        await storage.saveSession(token: 'tok', user: _user('TENANT'));
        server.on('POST', '/auth/logout', status: 204, body: '');

        await repo.logout();

        expect(server.last.path, '/api/auth/logout');
        expect(storage.hasSession, false);
      });

      test('efface la session même si le réseau manque', () async {
        await storage.saveSession(token: 'tok', user: _user('TENANT'));
        server.failWith = const SocketException('down');
        await repo.logout();
        expect(storage.hasSession, false);
      });
    });

    test('forgotPassword poste l\'e-mail', () async {
      server.on('POST', '/auth/forgot-password', body: {'message': 'ok'});
      await repo.forgotPassword('a@b.co');
      expect(server.last.json, {'email': 'a@b.co'});
    });
  });

  group('AnnouncementRepository', () {
    late AnnouncementRepository repo;
    setUp(() => repo = AnnouncementRepository(AnnouncementService(server.client)));

    test('list : filtres envoyés sous les noms du contrat, vides omis', () async {
      server.on('GET', '/announcements', body: {'data': [], 'meta': {'current_page': 1, 'last_page': 1, 'total': 0}});

      await repo.list(city: 'Cotonou', type: 'ROOM', minPrice: 30000, maxPrice: 100000, q: 'Akpakpa', page: 2);
      expect(server.last.query, {
        'city': 'Cotonou', 'type': 'ROOM', 'min_price': '30000', 'max_price': '100000',
        'q': 'Akpakpa', 'page': '2', 'per_page': '20',
      });

      await repo.list(city: '', type: null, q: '');
      expect(server.last.query.keys, unorderedEquals(['page', 'per_page']));
    });

    test('list : lit data et meta, calcule hasMore', () async {
      server.on('GET', '/announcements', body: {
        'data': [announcementJson(1), announcementJson(2, favorite: true)],
        'meta': {'current_page': 1, 'last_page': 3, 'total': 45},
      });

      final page = await repo.list();

      expect(page.items.map((a) => a.id), ['a1', 'a2']);
      expect(page.items[1].isFavorite, true);
      expect(page.hasMore, true);
    });

    test('list : meta absente -> une seule page', () async {
      server.on('GET', '/announcements', body: {'data': [announcementJson(1)]});
      final page = await repo.list(page: 4);
      expect(page.hasMore, false);
      expect(page.items, hasLength(1));
    });

    test('detail, favoris : routes du contrat', () async {
      server.on('GET', '/announcements/a1', body: {...announcementJson(1), 'description': 'Calme'});
      server.on('GET', '/me/favorites', body: {'data': [announcementJson(3)]});
      server.on('PUT', '/announcements/a1/favorite', body: {'message': 'ok'});
      server.on('DELETE', '/announcements/a1/favorite', status: 204, body: '');

      expect((await repo.detail('a1')).description, 'Calme');
      expect((await repo.favorites()).single.id, 'a3');
      await repo.setFavorite('a1', favorite: true);
      expect(server.last.method, 'PUT');
      await repo.setFavorite('a1', favorite: false);
      expect(server.last.method, 'DELETE');
    });

    test('detail d\'une annonce brouillon/inconnue -> 404 remonté', () async {
      server.on('GET', '/announcements/x', status: 404, body: {'message': 'Ressource introuvable.'});
      await expectLater(repo.detail('x'), throwsA(isA<ServerException>()));
    });
  });

  group('RentalRepository (B1)', () {
    late RentalRepository repo;
    setUp(() => repo = RentalRepository(RentalService(server.client)));

    test('lookup : code en query, aperçu lu', () async {
      server.on('GET', '/housings/lookup', body: {
        'housing': {'id': 'h', 'title': 'T', 'city': 'C', 'district': 'D', 'rent': 80000, 'owner_name': 'K M', 'due_day': 5, 'owner_verified': true},
      });

      final h = await repo.lookup('M4T-83P');

      expect(server.last.query, {'code': 'M4T-83P'});
      expect(h.rent, 80000);
      expect(h.ownerVerified, true);
    });

    test('lookup : code inconnu -> message du serveur', () async {
      server.on('GET', '/housings/lookup', status: 404, body: {'message': 'Ce code ne correspond à aucun logement.'});
      await expectLater(
        repo.lookup('ZZZ-000'),
        throwsA(isA<ServerException>().having((e) => e.message, 'm', 'Ce code ne correspond à aucun logement.')),
      );
    });

    test('join : poste le code ; 409 -> message du serveur', () async {
      server.on('POST', '/rentals/join', status: 201, body: {'message': 'ok', 'rental': {'status': 'PENDING'}});
      await repo.join('K7F-29X');
      expect(server.last.json, {'code': 'K7F-29X'});

      server.on('POST', '/rentals/join', status: 409, body: {'message': 'Vous avez déjà une location active ou en attente.'});
      await expectLater(repo.join('K7F-29X'), throwsA(isA<ServerException>().having((e) => e.message, 'm', contains('déjà'))));
    });
  });

  group('IdentityRepository (E7)', () {
    late IdentityRepository repo;
    late File idFile;
    late File selfieFile;
    setUp(() {
      repo = IdentityRepository(UploadService(server.client), AuthService(server.client));
      idFile = File('${Directory.systemTemp.path}/lofi_id.jpg')..writeAsBytesSync([1]);
      selfieFile = File('${Directory.systemTemp.path}/lofi_selfie.jpg')..writeAsBytesSync([2]);
      addTearDown(() {
        idFile.deleteSync();
        selfieFile.deleteSync();
      });
    });

    test('téléverse la pièce puis le selfie, puis envoie les deux URL', () async {
      var n = 0;
      server.on('POST', '/uploads', status: 201, body: {'url': 'https://x.test/1.jpg'});
      server.onRaw('POST', '/uploads', (s) async => http201('https://x.test/${++n}.jpg'));
      server.on('POST', '/me/identity', status: 201, body: {'status': 'PENDING'});

      await repo.submit(idImagePath: idFile.path, selfiePath: selfieFile.path);

      expect(server.seen.map((s) => s.path), ['/api/uploads', '/api/uploads', '/api/me/identity']);
      expect(server.seen[0].body, contains('identity_id'));
      expect(server.seen[1].body, contains('identity_selfie'));
      expect(server.last.json, {'id_image_url': 'https://x.test/1.jpg', 'selfie_url': 'https://x.test/2.jpg'});
    });

    test('réponse d\'upload sans URL -> ServerException et rien n\'est envoyé', () async {
      server.on('POST', '/uploads', status: 201, body: {});
      await expectLater(repo.submit(idImagePath: idFile.path, selfiePath: selfieFile.path), throwsA(isA<ServerException>()));
      expect(server.seen.where((s) => s.path.endsWith('/me/identity')), isEmpty);
    });

    test('compte non propriétaire (403) -> erreur remontée', () async {
      server.on('POST', '/uploads', status: 201, body: {'url': 'https://x.test/a.jpg'});
      server.on('POST', '/me/identity', status: 403, body: {'message': 'Action réservée aux propriétaires.'});
      await expectLater(
        repo.submit(idImagePath: idFile.path, selfiePath: selfieFile.path),
        throwsA(isA<ServerException>().having((e) => e.message, 'm', contains('propriétaires'))),
      );
    });
  });
}

UserModel _user(String role) => UserModel.fromJson({...userJson, 'role': role});

Future<http.Response> http201(String url) async =>
    http.Response('{"url":"$url"}', 201, headers: {'content-type': 'application/json'});
