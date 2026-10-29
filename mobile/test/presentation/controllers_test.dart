import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:mobile/presentation/routes/app_routes.dart';
import 'package:mobile/data/remote/services/announcement_service.dart';
import 'package:mobile/data/remote/services/auth_service.dart';
import 'package:mobile/data/remote/services/rental_service.dart';
import 'package:mobile/data/repo/announcement_repository.dart';
import 'package:mobile/data/repo/auth_repository.dart';
import 'package:mobile/data/repo/rental_repository.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/domain/models/search_preferences.dart';
import 'package:mobile/presentation/features/auth/auth_controller.dart';
import 'package:mobile/presentation/features/listings/listing_details_controller.dart';
import 'package:mobile/presentation/features/listings/listings_controller.dart';
import 'package:mobile/presentation/features/rental/join_housing_controller.dart';
import 'package:mobile/presentation/shared/load_status.dart';

import 'package:mobile/domain/models/user_model.dart';

import '../support/fakes.dart';

class UserModelX {
  static UserModel of(String role) => UserModel.fromJson({...userJson, 'role': role});
}

http.Response httpJson(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.testMode = true;
  });
  tearDown(Get.reset);

  final navigated = <String>[];
  late FakeServer server;
  late MemoryAuthStorage auth;
  late MemoryAppStorage app;

  void boot() {
    auth = MemoryAuthStorage();
    app = MemoryAppStorage();
    server = FakeServer(storage: auth);
  }

  Future<void> loginAs(String role) =>
      auth.saveSession(token: 't', user: UserModelX.of(role));

  ListingsController listings() => ListingsController(
        repository: AnnouncementRepository(AnnouncementService(server.client)),
        authStorage: auth,
        appStorage: app,
      );

  Map<String, dynamic> page(List<int> ids, {int current = 1, int last = 1}) => {
        'data': ids.map(announcementJson).toList(),
        'meta': {'current_page': current, 'last_page': last, 'total': ids.length},
      };

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

  /// Test dont le code affiche un snackbar : il lui faut une vraie app (Overlay) autour.
  void withApp(String name, Future<void> Function() body) {
    testWidgets(name, (tester) async {
      navigated.clear();
      await tester.pumpWidget(GetMaterialApp(
        home: const SizedBox(),
        getPages: [
          for (final name in [AppRoutes.login, AppRoutes.rentTracking, AppRoutes.listings, AppRoutes.ownerOnboarding, AppRoutes.onboardingVille, AppRoutes.ownerDashboard])
            GetPage(name: name, page: () => const SizedBox()),
        ],
        routingCallback: (r) {
          if (r?.current != null) navigated.add(r!.current);
        },
      ));
      await tester.runAsync(body);
      // Laisse les snackbars s'afficher puis se retirer d'eux-mêmes (fermer à la main plante GetX).
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  group('ListingsController (A1/A4)', () {
    setUp(boot);

    test('charge le fil au démarrage', () async {
      server.on('GET', '/announcements', body: page([1, 2]));
      final c = listings()..onInit();
      await settle();

      expect(c.status.value, LoadStatus.loaded);
      expect(c.items.map((a) => a.id), ['a1', 'a2']);
      expect(c.hasMore.value, false);
    });

    test('applique les critères de l\'onboarding dans la requête', () async {
      app.savePreferences(const SearchPreferences(types: ['Chambre'])
          .copyWith(city: 'Abomey-Calavi', budgetLabel: 'Moins de 100 000 FCFA'));
      server.on('GET', '/announcements', body: page([]));

      listings().onInit();
      await settle();

      expect(server.last.query['city'], 'Abomey-Calavi');
      expect(server.last.query['type'], 'ROOM');
      expect(server.last.query['max_price'], '100000');
      expect(server.last.query.containsKey('min_price'), false);
    });

    test('« Voir tous les logements » retire les critères', () async {
      app.savePreferences(const SearchPreferences().copyWith(city: 'Cotonou'));
      server.on('GET', '/announcements', body: page([1]));
      final c = listings()..onInit();
      await settle();
      expect(server.last.query['city'], 'Cotonou');

      c.showAll();
      await settle();

      expect(server.last.query.containsKey('city'), false);
      expect(c.usePreferences.value, false);
    });

    test('recherche : le texte part en paramètre q et recharge à la page 1', () async {
      server.on('GET', '/announcements', body: page([1]));
      final c = listings()..onInit();
      await settle();

      c.search('Fidjrossè');
      await settle();

      expect(server.last.query['q'], 'Fidjrossè');
      expect(server.last.query['page'], '1');
    });

    test('pagination : loadMore ajoute la page suivante puis s\'arrête', () async {
      var call = 0;
      server.onRaw('GET', '/announcements', (s) async {
        call++;
        final p = int.parse(s.query['page']!);
        return httpJson(page([p * 10, p * 10 + 1], current: p, last: 2));
      });
      final c = listings()..onInit();
      await settle();
      expect(c.hasMore.value, true);

      await c.loadMore();
      expect(c.items.map((a) => a.id), ['a10', 'a11', 'a20', 'a21']);
      expect(c.hasMore.value, false);

      await c.loadMore();
      expect(call, 2, reason: 'plus de page : aucun appel supplémentaire');
    });

    test('loadMore ignoré pendant un chargement déjà en cours', () async {
      server.on('GET', '/announcements', body: page([1], current: 1, last: 5));
      final c = listings()..onInit();
      await settle();

      await Future.wait([c.loadMore(), c.loadMore(), c.loadMore()]);

      expect(server.seen.where((s) => s.query['page'] == '2'), hasLength(1));
    });

    test('échec réseau pendant loadMore : la liste affichée est conservée', () async {
      var first = true;
      server.onRaw('GET', '/announcements', (s) async {
        if (first) {
          first = false;
          return httpJson(page([1], current: 1, last: 2));
        }
        return httpJson({'message': 'x'}, 500);
      });
      final c = listings()..onInit();
      await settle();

      await c.loadMore();

      expect(c.items, hasLength(1));
      expect(c.status.value, LoadStatus.loaded);
      expect(c.loadingMore.value, false);
    });

    test('erreur serveur : statut failure + message', () async {
      server.on('GET', '/announcements', status: 500, body: {});
      final c = listings()..onInit();
      await settle();

      expect(c.status.value, LoadStatus.failure);
      expect(c.errorMessage.value, isNotEmpty);
    });

    test('un favori déjà marqué par le serveur est reconnu', () async {
      server.on('GET', '/announcements', body: {'data': [announcementJson(1, favorite: true), announcementJson(2)], 'meta': {}});
      final c = listings()..onInit();
      await settle();

      expect(c.isFavorite('a1'), true);
      expect(c.isFavorite('a2'), false);
    });

    test('favori : mise à jour immédiate puis appel PUT, et DELETE au second appui', () async {
      await loginAs('TENANT');
      server.on('GET', '/announcements', body: page([1]));
      server.on('PUT', '/announcements/a1/favorite', body: {});
      server.on('DELETE', '/announcements/a1/favorite', status: 204, body: '');
      final c = listings()..onInit();
      await settle();

      await c.toggleFavorite(c.items.first);
      expect(c.isFavorite('a1'), true);
      expect(server.last.method, 'PUT');
      expect(c.favorites.single.isFavorite, true);

      await c.toggleFavorite(c.items.first);
      expect(c.isFavorite('a1'), false);
      expect(server.last.method, 'DELETE');
      expect(c.favorites, isEmpty);
    });

    withApp('favori : si le serveur refuse, l\'état est annulé', () async {
      await loginAs('TENANT');
      server.on('GET', '/announcements', body: page([1]));
      server.on('PUT', '/announcements/a1/favorite', status: 404, body: {'message': 'Ressource introuvable.'});
      final c = listings()..onInit();
      await settle();

      await c.toggleFavorite(c.items.first);

      expect(c.isFavorite('a1'), false);
      expect(c.favorites, isEmpty);
    });

    withApp('favori : refusé sans appel réseau pour un visiteur ou un propriétaire', () async {
      server.on('GET', '/announcements', body: page([1]));
      final c = listings()..onInit();
      await settle();
      final before = server.seen.length;

      await c.toggleFavorite(c.items.first);
      expect(server.seen.length, before);
      expect(c.isFavorite('a1'), false);
      expect(navigated, contains('/login'), reason: 'un visiteur est invité à se connecter');

      navigated.clear();
      await loginAs('OWNER');
      await c.toggleFavorite(c.items.first);
      expect(server.seen.length, before);
      expect(navigated, isNot(contains('/login')), reason: 'un propriétaire connecté n\'est pas renvoyé vers la connexion');
    });

    test('loadFavorites : liste du serveur pour un locataire, vide sans appel sinon', () async {
      server.on('GET', '/announcements', body: page([]));
      server.on('GET', '/me/favorites', body: {'data': [announcementJson(7)]});
      final c = listings()..onInit();
      await settle();

      await c.loadFavorites();
      expect(c.favorites, isEmpty);
      expect(server.seen.where((s) => s.path.endsWith('/me/favorites')), isEmpty);

      await loginAs('TENANT');
      await c.loadFavorites();
      expect(c.favorites.single.id, 'a7');
      expect(c.isFavorite('a7'), true);
      expect(c.favoritesStatus.value, LoadStatus.loaded);
    });
  });

  group('ListingDetailsController (A3)', () {
    setUp(boot);

    ListingDetailsController details(String id) {
      Get.parameters = {'id': id};
      return ListingDetailsController(
        repository: AnnouncementRepository(AnnouncementService(server.client)),
        authStorage: auth,
      );
    }

    test('charge le détail de l\'id du chemin', () async {
      server.on('GET', '/announcements/a9', body: {...announcementJson(9, favorite: true), 'description': 'Calme'});
      final c = details('a9')..onInit();
      await settle();

      expect(c.status.value, LoadStatus.loaded);
      expect(c.item.value!.description, 'Calme');
      expect(c.isFavorite.value, true);
    });

    test('annonce introuvable : failure avec message du serveur', () async {
      server.on('GET', '/announcements/zz', status: 404, body: {'message': 'Ressource introuvable.'});
      final c = details('zz')..onInit();
      await settle();

      expect(c.status.value, LoadStatus.failure);
      expect(c.errorMessage.value, 'Ressource introuvable.');
    });

    test('favori du détail répercuté sur la liste si elle existe', () async {
      await loginAs('TENANT');
      server.on('GET', '/announcements', body: page([9]));
      server.on('GET', '/announcements/a9', body: announcementJson(9));
      server.on('PUT', '/announcements/a9/favorite', body: {});
      final list = Get.put(listings());
      await settle();
      final c = details('a9')..onInit();
      await settle();

      await c.toggleFavorite();

      expect(c.isFavorite.value, true);
      expect(list.isFavorite('a9'), true);
    });

    withApp('favori refusé par le serveur : état annulé', () async {
      await loginAs('TENANT');
      server.on('GET', '/announcements/a9', body: announcementJson(9));
      server.on('PUT', '/announcements/a9/favorite', status: 500, body: {});
      final c = details('a9')..onInit();
      await settle();

      await c.toggleFavorite();

      expect(c.isFavorite.value, false);
    });

    withApp('visiteur : aucun appel favori', () async {
      server.on('GET', '/announcements/a9', body: announcementJson(9));
      final c = details('a9')..onInit();
      await settle();
      final before = server.seen.length;

      await c.toggleFavorite();

      expect(server.seen.length, before);
      expect(navigated, contains('/login'));
    });
  });

  group('JoinHousingController (B1)', () {
    setUp(boot);

    JoinHousingController join() => JoinHousingController(
          repository: RentalRepository(RentalService(server.client)),
          authStorage: auth,
        );

    final housing = {
      'housing': {'id': 'h', 'title': 'Appartement 1A', 'city': 'Cotonou', 'district': 'Fidjrossè', 'rent': 150000, 'owner_name': 'K M', 'due_day': 5, 'owner_verified': true},
    };

    test('code incomplet : aucune recherche', () async {
      final c = join();
      await c.onCodeChanged('M4T-8');

      expect(server.seen, isEmpty);
      expect(c.lookupStatus.value, LoadStatus.initial);
      expect(c.housing.value, isNull);
    });

    test('code complet : recherche puis aperçu', () async {
      server.on('GET', '/housings/lookup', body: housing);
      final c = join();

      await c.onCodeChanged('M4T-83P');

      expect(c.lookupStatus.value, LoadStatus.loaded);
      expect(c.housing.value!.rent, 150000);
      expect(c.codeError.value, isNull);
    });

    test('code inconnu : message d\'erreur sous le champ', () async {
      server.on('GET', '/housings/lookup', status: 404, body: {'message': 'Ce code ne correspond à aucun logement.'});
      final c = join();

      await c.onCodeChanged('ZZZ-000');

      expect(c.lookupStatus.value, LoadStatus.failure);
      expect(c.codeError.value, 'Ce code ne correspond à aucun logement.');
      expect(c.housing.value, isNull);
    });

    test('modifier le code efface l\'aperçu et l\'erreur', () async {
      server.on('GET', '/housings/lookup', body: housing);
      final c = join();
      await c.onCodeChanged('M4T-83P');

      await c.onCodeChanged('M4T-83');

      expect(c.housing.value, isNull);
      expect(c.codeError.value, isNull);
      expect(c.lookupStatus.value, LoadStatus.initial);
    });

    test('réponse tardive d\'un ancien code ignorée (course)', () async {
      final slow = Completer<http.Response>();
      server.onRaw('GET', '/housings/lookup', (s) async {
        if (s.query['code'] == 'AAA-111') return slow.future;
        return httpJson(housing);
      });
      final c = join();

      final first = c.onCodeChanged('AAA-111');
      await c.onCodeChanged('M4T-83P');
      slow.complete(httpJson({'housing': {'id': 'old', 'rent': 1}}));
      await first;

      expect(c.housing.value!.id, 'h', reason: 'l\'aperçu du dernier code saisi gagne');
    });

    test('confirm sans aperçu : rien n\'est envoyé', () async {
      final c = join();
      await c.confirm();
      expect(server.seen, isEmpty);
    });

    test('confirm sans session : pas d\'appel /rentals/join', () async {
      server.on('GET', '/housings/lookup', body: housing);
      final c = join();
      await c.onCodeChanged('M4T-83P');

      await c.confirm();

      expect(server.seen.where((s) => s.path.endsWith('/rentals/join')), isEmpty);
      expect(navigated, contains('/login'));
    });

    withApp('confirm connecté : POST du code, joining repasse à false', () async {
      await loginAs('TENANT');
      server.on('GET', '/housings/lookup', body: housing);
      server.on('POST', '/rentals/join', status: 201, body: {'message': 'ok'});
      final c = join();
      await c.onCodeChanged('M4T-83P');

      await c.confirm();

      expect(server.last.json, {'code': 'M4T-83P'});
      expect(c.joining.value, false);
      expect(c.codeError.value, isNull);
      expect(navigated, contains('/rent-tracking'));
    });

    withApp('confirm : 409 « déjà une location » affiché sous le champ', () async {
      await loginAs('TENANT');
      server.on('GET', '/housings/lookup', body: housing);
      server.on('POST', '/rentals/join', status: 409, body: {'message': 'Vous avez déjà une location active ou en attente.'});
      final c = join();
      await c.onCodeChanged('M4T-83P');

      await c.confirm();

      expect(c.codeError.value, contains('déjà une location'));
      expect(c.joining.value, false);
    });

    withApp('double appui sur confirmer : un seul POST', () async {
      await loginAs('TENANT');
      server.on('GET', '/housings/lookup', body: housing);
      server.on('POST', '/rentals/join', status: 201, body: {});
      final c = join();
      await c.onCodeChanged('M4T-83P');

      await Future.wait([c.confirm(), c.confirm()]);

      expect(server.seen.where((s) => s.path.endsWith('/rentals/join')), hasLength(1));
    });

    test('reset : retour à l\'état initial', () async {
      server.on('GET', '/housings/lookup', body: housing);
      final c = join();
      await c.onCodeChanged('M4T-83P');

      c.reset();

      expect(c.housing.value, isNull);
      expect(c.lookupStatus.value, LoadStatus.initial);
    });
  });

  group('AuthController (A5/A6)', () {
    setUp(boot);

    AuthController authCtrl() =>
        AuthController(repository: AuthRepository(AuthService(server.client), auth));

    test('connexion réussie : statut loaded, session ouverte, e-mail nettoyé', () async {
      server.on('POST', '/auth/login', body: {'token': 'tok', 'user': userJson});
      final c = authCtrl();

      await c.login(email: '  patrick@lofi.bj ', password: 'Test1234');

      expect(c.status.value, LoadStatus.loaded);
      expect(server.last.json['email'], 'patrick@lofi.bj');
      expect(auth.hasSession, true);
    });

    test('mauvais mot de passe : message du serveur, pas de session', () async {
      server.on('POST', '/auth/login', status: 401, body: {'message': 'Email ou mot de passe incorrect.'});
      final c = authCtrl();

      await c.login(email: 'a@b.co', password: 'x');

      expect(c.status.value, LoadStatus.failure);
      expect(c.errorMessage.value, 'Email ou mot de passe incorrect.');
      expect(auth.hasSession, false);
    });

    test('réseau coupé à l\'inscription : message clair, bouton redevient actif', () async {
      server.failWith = const SocketException('unreachable');
      final c = authCtrl();

      await c.register(fullName: 'A B', email: 'a@b.co', phone: '0197123456', password: 'Test1234');

      expect(c.status.value, LoadStatus.failure);
      expect(c.errorMessage.value, isNotEmpty);
      expect(c.isLoading, false);
    });

    test('inscription : espaces retirés du téléphone, rôle choisi envoyé', () async {
      server.on('POST', '/auth/register', status: 201, body: {'token': 't', 'user': {...userJson, 'role': 'OWNER'}});
      final c = authCtrl()..selectRole(UserRole.OWNER);

      await c.register(fullName: ' Koffi Mensah ', email: ' k@lofi.bj ', phone: '01 97 00 00 01', password: 'Test1234');

      expect(server.last.json['telephone'], '0197000001');
      expect(server.last.json['role'], 'OWNER');
      expect(server.last.json['email'], 'k@lofi.bj');
      expect(c.status.value, LoadStatus.loaded);
    });

    test('inscription : erreur de champ du serveur affichée', () async {
      server.on('POST', '/auth/register', status: 422, body: {
        'errors': {'telephone': ['Ce numéro de téléphone est déjà utilisé.']},
      });
      final c = authCtrl();

      await c.register(fullName: 'A B', email: 'a@b.co', phone: '0197123456', password: 'Test1234');

      expect(c.errorMessage.value, 'Ce numéro de téléphone est déjà utilisé.');
    });

    test('double soumission ignorée pendant le chargement', () async {
      server.on('POST', '/auth/login', body: {'token': 't', 'user': userJson});
      final c = authCtrl();

      await Future.wait([
        c.login(email: 'a@b.co', password: 'x'),
        c.login(email: 'a@b.co', password: 'x'),
      ]);

      expect(server.seen.where((s) => s.path.endsWith('/auth/login')), hasLength(1));
    });

    test('état initial : mot de passe masqué, locataire, conditions non cochées', () {
      final c = authCtrl();
      expect(c.hidePassword.value, true);
      expect(c.role.value, UserRole.TENANT);
      expect(c.acceptedTerms.value, false);
      c.togglePassword();
      expect(c.hidePassword.value, false);
    });
  });
}
