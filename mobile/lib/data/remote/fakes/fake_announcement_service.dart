import '../../../core/errors/app_exception.dart';
import '../services/announcement_service.dart';

/// FAUX service d'annonces, pour développer sans API.
/// Actif uniquement avec `--dart-define=USE_FAKE_API=true` (voir ListingBinding).
/// Imite les filtres et la pagination du serveur ; les favoris sont gardés en mémoire.
class FakeAnnouncementService extends AnnouncementService {
  FakeAnnouncementService(super.api);

  static const _delay = Duration(milliseconds: 500);

  final _favorites = <String>{'3', '4'};

  static const _all = <Map<String, dynamic>>[
    {
      'id': '1', 'title': 'Appartement · 3 pièces', 'type': 'HOUSE', 'rent': 250000,
      'deposit_months': 2, 'city': 'Cotonou', 'district': 'Fidjrossè', 'rooms': 3,
      'photos': <String>[], 'verified': true, 'status': 'PUBLISHED',
      'published_at': '2026-10-20T09:00:00Z',
      'description': "Appartement lumineux au 2e étage d'un immeuble sécurisé.",
      'owner': {'id': '7', 'name': 'Koffi Mensah'},
    },
    {
      'id': '2', 'title': 'Maison · 4 pièces', 'type': 'HOUSE', 'rent': 280000,
      'deposit_months': 2, 'city': 'Cotonou', 'district': 'Haie Vive', 'rooms': 4,
      'photos': <String>[], 'verified': false, 'status': 'PUBLISHED',
      'published_at': '2026-10-19T09:00:00Z',
      'description': 'Maison avec cour fermée et deux places de parking.',
      'owner': {'id': '8', 'name': 'Awa Sanni'},
    },
    {
      'id': '3', 'title': 'Appartement · 3 pièces · 85 m²', 'type': 'HOUSE', 'rent': 350000,
      'deposit_months': 3, 'city': 'Cotonou', 'district': 'Fidjrossè', 'rooms': 3,
      'photos': <String>[], 'verified': true, 'status': 'PUBLISHED',
      'published_at': '2026-10-18T09:00:00Z',
      'description': 'Salon, deux chambres, cuisine équipée et balcon, à 400 m de la plage.',
      'owner': {'id': '7', 'name': 'Koffi Mensah'},
    },
    {
      'id': '4', 'title': 'Studio · 1 pièce', 'type': 'ROOM', 'rent': 80000,
      'deposit_months': 1, 'city': 'Cotonou', 'district': 'Akpakpa', 'rooms': 1,
      'photos': <String>[], 'verified': false, 'status': 'PUBLISHED',
      'published_at': '2026-10-17T09:00:00Z',
      'description': 'Studio meublé, eau et électricité à compteur personnel.',
      'owner': {'id': '8', 'name': 'Awa Sanni'},
    },
    {
      'id': '5', 'title': 'Maison · 4 pièces', 'type': 'HOUSE', 'rent': 250000,
      'deposit_months': 2, 'city': 'Abomey-Calavi', 'district': 'Togoudo', 'rooms': 4,
      'photos': <String>[], 'verified': true, 'status': 'PUBLISHED',
      'published_at': '2026-10-16T09:00:00Z',
      'description': 'Maison récente dans un quartier calme.',
      'owner': {'id': '7', 'name': 'Koffi Mensah'},
    },
  ];

  Map<String, dynamic> _view(Map<String, dynamic> a, {bool detail = false}) => {
        ...a,
        'is_favorite': _favorites.contains(a['id']),
        if (!detail) 'description': null,
        if (!detail) 'owner': null,
      };

  bool _contains(Object? value, String needle) =>
      '$value'.toLowerCase().contains(needle.toLowerCase());

  @override
  Future<Map<String, dynamic>> list({
    String? city,
    String? type,
    int? minPrice,
    int? maxPrice,
    String? q,
    int page = 1,
    int perPage = 20,
  }) async {
    await Future<void>.delayed(_delay);
    final filtered = _all.where((a) {
      if (city != null && city.isNotEmpty && !_contains(a['city'], city)) return false;
      if (type != null && type.isNotEmpty && a['type'] != type) return false;
      if (minPrice != null && (a['rent'] as int) < minPrice) return false;
      if (maxPrice != null && (a['rent'] as int) > maxPrice) return false;
      if (q != null && q.isNotEmpty && !_contains(a['title'], q) && !_contains(a['district'], q)) {
        return false;
      }
      return true;
    }).toList();
    final start = (page - 1) * perPage;
    final slice = filtered.skip(start).take(perPage).map(_view).toList();
    return {
      'data': slice,
      'meta': {
        'current_page': page,
        'last_page': (filtered.length / perPage).ceil().clamp(1, 9999),
        'total': filtered.length,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> detail(String id) async {
    await Future<void>.delayed(_delay);
    final found = _all.where((a) => a['id'] == id);
    if (found.isEmpty) throw const ServerException('Ressource introuvable.');
    return _view(found.first, detail: true);
  }

  @override
  Future<Map<String, dynamic>> favorites() async {
    await Future<void>.delayed(_delay);
    return {
      'data': _all.where((a) => _favorites.contains(a['id'])).map(_view).toList(),
    };
  }

  @override
  Future<void> addFavorite(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _favorites.add(id);
  }

  @override
  Future<void> removeFavorite(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _favorites.remove(id);
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    await Future<void>.delayed(_delay);
    return {'id': 'fake-${DateTime.now().millisecondsSinceEpoch}', ...body, 'status': 'DRAFT'};
  }

  @override
  Future<Map<String, dynamic>> publish(String id) async {
    await Future<void>.delayed(_delay);
    return {'message': 'Annonce publiée avec succès.'};
  }
}
