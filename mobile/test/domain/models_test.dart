import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/models/announcement_model.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/domain/models/rental_model.dart';
import 'package:mobile/domain/models/search_preferences.dart';
import 'package:mobile/domain/models/user_model.dart';

import '../support/fakes.dart';

void main() {
  group('UserModel', () {
    test('lit le format du contrat', () {
      final u = UserModel.fromJson(userJson);
      expect(u.id, 'u1');
      expect(u.role, UserRole.TENANT);
      expect(u.fullName, 'Patrick Agossa');
      expect(u.initials, 'PA');
    });
    test('toJson ↔ fromJson sans perte', () {
      final u = UserModel.fromJson({...userJson, 'role': 'OWNER', 'actif': false});
      final again = UserModel.fromJson(u.toJson());
      expect(again.role, UserRole.OWNER);
      expect(again.actif, false);
      expect(again.email, u.email);
    });
    test('id numérique accepté', () => expect(UserModel.fromJson({...userJson, 'id': 42}).id, '42'));
    test('rôles : casse, équivalents français, inconnu -> TENANT', () {
      UserRole role(Object? r) => UserModel.fromJson({...userJson, 'role': r}).role;
      expect(role('owner'), UserRole.OWNER);
      expect(role('Propriétaire'), UserRole.OWNER);
      expect(role('admin'), UserRole.ADMIN);
      expect(role('???'), UserRole.TENANT);
      expect(role(null), UserRole.TENANT);
    });
    test('champs manquants : pas de plantage', () {
      final u = UserModel.fromJson({});
      expect(u.fullName, '');
      expect(u.initials, '');
      expect(u.actif, true);
    });
    test('initiales avec prénom vide', () => expect(UserModel.fromJson({...userJson, 'prenoms': ''}).initials, 'A'));
  });

  group('AnnouncementModel', () {
    test('contrat complet (fil)', () {
      final a = AnnouncementModel.fromJson(announcementJson(1, favorite: true, type: 'HOUSE', rent: 120000));
      expect(a.id, 'a1');
      expect(a.type, AccommodationType.HOUSE);
      expect(a.rent, 120000);
      expect(a.isFavorite, true);
      expect(a.status, AnnouncementStatus.PUBLISHED);
      expect(a.publishedAt, isNotNull);
      expect(a.ownerName, '');
    });
    test('détail : description et propriétaire', () {
      final a = AnnouncementModel.fromJson({
        ...announcementJson(1),
        'description': 'Calme',
        'owner': {'id': 'o1', 'name': 'Koffi Mensah'},
      });
      expect(a.description, 'Calme');
      expect(a.ownerId, 'o1');
      expect(a.ownerName, 'Koffi Mensah');
    });
    test('valeurs inattendues -> valeurs par défaut sûres', () {
      final a = AnnouncementModel.fromJson({'id': 1, 'type': 'CHATEAU', 'status': 'X', 'rent': '75000', 'rooms': null, 'photos': null});
      expect(a.type, AccommodationType.OTHER);
      expect(a.status, AnnouncementStatus.PUBLISHED);
      expect(a.rent, 75000);
      expect(a.rooms, 1);
      expect(a.photos, isEmpty);
      expect(a.firstPhoto, isNull);
      expect(a.publishedAt, isNull);
    });
    test('photos non texte ignorées, première photo', () {
      final a = AnnouncementModel.fromJson({...announcementJson(1), 'photos': ['https://x/1.jpg', 3, null, 'https://x/2.jpg']});
      expect(a.photos, ['https://x/1.jpg', 'https://x/2.jpg']);
      expect(a.firstPhoto, 'https://x/1.jpg');
    });
    test('loyer décimal arrondi', () => expect(AnnouncementModel.fromJson({'rent': 1999.6}).rent, 2000));
    test('location : séparateur propre si quartier ou ville vide', () {
      expect(AnnouncementModel.fromJson({'district': 'A', 'city': 'B'}).location, 'A, B');
      expect(AnnouncementModel.fromJson({'district': '', 'city': 'B'}).location, 'B');
      expect(AnnouncementModel.fromJson({'district': 'A', 'city': ' '}).location, 'A');
    });
    test('copyWith ne change que le favori', () {
      final a = AnnouncementModel.fromJson({...announcementJson(1), 'description': 'd'});
      final b = a.copyWith(isFavorite: true);
      expect(b.isFavorite, true);
      expect(b.description, 'd');
      expect(b.id, a.id);
      expect(a.isFavorite, false);
    });
  });

  group('AnnouncementPage', () {
    test('hasMore', () {
      expect(const AnnouncementPage(items: [], currentPage: 1, lastPage: 3).hasMore, true);
      expect(const AnnouncementPage(items: [], currentPage: 3, lastPage: 3).hasMore, false);
      expect(const AnnouncementPage(items: [], currentPage: 1, lastPage: 1).hasMore, false);
    });
  });

  group('HousingPreview', () {
    test('format de /housings/lookup', () {
      final h = HousingPreview.fromJson({
        'housing': {
          'id': 'h1', 'title': 'Appartement 1A', 'city': 'Cotonou', 'district': 'Fidjrossè',
          'rent': 150000, 'due_day': 5, 'owner_verified': true, 'owner_name': 'Koffi Mensah',
        },
      });
      expect(h.rent, 150000);
      expect(h.dueDay, 5);
      expect(h.ownerVerified, true);
      expect(h.location, 'Fidjrossè, Cotonou');
    });
    test('champs facultatifs absents', () {
      final h = HousingPreview.fromJson({'housing': {'id': '3', 'rent': '85000'}});
      expect(h.rent, 85000);
      expect(h.dueDay, isNull);
      expect(h.ownerVerified, false);
    });
    test('enveloppe `data` ou JSON à plat acceptés', () {
      expect(HousingPreview.fromJson({'data': {'id': 'x', 'rent': 1}}).id, 'x');
      expect(HousingPreview.fromJson({'id': 'y', 'rent': 2}).id, 'y');
    });
  });

  group('SearchPreferences', () {
    test('vide par défaut', () => expect(const SearchPreferences().isEmpty, true));

    test('budgets de l\'écran E4 -> bornes', () {
      expect(SearchPreferences.rangeOf('Moins de 100 000 FCFA'), (null, 100000));
      expect(SearchPreferences.rangeOf('100 000 à 300 000 FCFA'), (100000, 300000));
      expect(SearchPreferences.rangeOf('300 000 à 500 000 FCFA'), (300000, 500000));
      expect(SearchPreferences.rangeOf('Plus de 500 000 FCFA'), (500000, null));
      expect(SearchPreferences.rangeOf('Autre'), (null, null));
    });

    test('apiType : un seul type API déduit, sinon null', () {
      expect(const SearchPreferences(types: ['Chambre']).apiType, 'ROOM');
      expect(const SearchPreferences(types: ['Chambre', 'Studio']).apiType, 'ROOM');
      expect(const SearchPreferences(types: ['Maison', 'Appartement']).apiType, 'HOUSE');
      expect(const SearchPreferences(types: ['Chambre', 'Maison']).apiType, isNull);
      expect(const SearchPreferences().apiType, isNull);
    });

    test('copyWith du budget met à jour les bornes, sans budget les conserve', () {
      final p = const SearchPreferences().copyWith(budgetLabel: '100 000 à 300 000 FCFA');
      expect((p.minPrice, p.maxPrice), (100000, 300000));
      final q = p.copyWith(city: 'Cotonou');
      expect((q.minPrice, q.maxPrice), (100000, 300000));
      expect(q.city, 'Cotonou');
    });

    test('JSON aller-retour', () {
      final p = const SearchPreferences(neighborhoods: ['Akpakpa'], types: ['Studio'])
          .copyWith(city: 'Cotonou', budgetLabel: 'Plus de 500 000 FCFA');
      final again = SearchPreferences.fromJson(p.toJson());
      expect(again.city, 'Cotonou');
      expect(again.neighborhoods, ['Akpakpa']);
      expect(again.types, ['Studio']);
      expect((again.minPrice, again.maxPrice), (500000, null));
      expect(again.isEmpty, false);
    });

    test('fromJson tolère données corrompues', () {
      final p = SearchPreferences.fromJson({'city': null, 'types': 'oops', 'minPrice': 'x'});
      expect(p.city, '');
      expect(p.types, isEmpty);
      expect(p.isEmpty, true);
    });
  });

  test('énumérations alignées sur le contrat de l\'API', () {
    expect(UserRole.values.map((e) => e.name), ['TENANT', 'OWNER', 'ADMIN']);
    expect(RentalStatus.values.map((e) => e.name), ['PENDING', 'ACTIVE', 'FINISHED']);
    expect(RentStatus.values.map((e) => e.name), ['PAID', 'PARTIAL', 'LATE', 'UPCOMING']);
    expect(PaymentStatus.values.map((e) => e.name), ['PENDING', 'SUCCESS', 'FAILED']);
    expect(Operator.values.map((e) => e.name), containsAll(['MTN', 'MOOV', 'CASH']));
    expect(IdentityStatus.values.map((e) => e.name), ['PENDING', 'APPROVED', 'REJECTED']);
    expect(AccommodationType.values.map((e) => e.name), ['HOUSE', 'ROOM', 'OTHER']);
  });
}
