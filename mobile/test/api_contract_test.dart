import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/remote/fakes/fake_announcement_service.dart';
import 'package:mobile/data/repo/announcement_repository.dart';
import 'package:mobile/domain/models/announcement_model.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:mobile/domain/models/rental_model.dart';
import 'package:mobile/domain/models/search_preferences.dart';

/// ApiClient jamais appelé : les faux services ne l'utilisent pas.
class _UnusedApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('AnnouncementModel lit le format du contrat', () {
    final a = AnnouncementModel.fromJson({
      'id': 45,
      'title': 'Studio meublé à Fidjrossè',
      'type': 'ROOM',
      'rent': 75000,
      'deposit_months': 2,
      'city': 'Cotonou',
      'district': 'Fidjrossè',
      'rooms': 1,
      'photos': ['https://res.cloudinary.com/x/image/upload/v1/a.jpg'],
      'verified': true,
      'is_favorite': false,
      'status': 'PUBLISHED',
      'published_at': '2026-10-20T09:00:00Z',
      'owner': {'id': 7, 'name': 'Koffi Mensah'},
    });
    expect(a.id, '45');
    expect(a.type, AccommodationType.ROOM);
    expect(a.location, 'Fidjrossè, Cotonou');
    expect(a.ownerName, 'Koffi Mensah');
    expect(a.firstPhoto, isNotNull);
  });

  test('HousingPreview lit la réponse de /housings/lookup', () {
    final h = HousingPreview.fromJson({
      'housing': {'id': '3', 'title': 'A', 'city': 'Cotonou', 'district': 'Akpakpa', 'rent': 85000, 'owner_name': 'K M'},
    });
    expect(h.rent, 85000);
    expect(h.dueDay, isNull);
  });

  test('SearchPreferences : budget et type', () {
    final p = const SearchPreferences().copyWith(
      types: ['Appartement', 'Maison'],
      budgetLabel: '100 000 à 300 000 FCFA',
    );
    expect(p.minPrice, 100000);
    expect(p.maxPrice, 300000);
    expect(p.apiType, 'HOUSE');
    expect(const SearchPreferences().copyWith(types: ['Studio', 'Maison']).apiType, isNull);
  });

  test('Fil factice : filtres et pagination', () async {
    final repo = AnnouncementRepository(FakeAnnouncementService(_UnusedApi()));
    final page = await repo.list(city: 'Cotonou', maxPrice: 300000);
    expect(page.items.map((e) => e.id), ['1', '2', '4']);
    expect(page.hasMore, isFalse);
  });
}
