import '../../../core/errors/app_exception.dart';
import '../services/property_service.dart';

/// Service simulé de gestion des logements pour le mode sans serveur (`USE_FAKE_API=true`).
class FakePropertyService extends PropertyService {
  FakePropertyService(super.api);

  static const _delay = Duration(milliseconds: 400);

  final List<Map<String, dynamic>> _storage = [
    {
      'id': 'housing-1',
      'owner_id': 'proprio@lofi.bj',
      'title': 'Appartement 1A',
      'type': 'HOUSE',
      'rent': 150000,
      'due_day': 5,
      'city': 'Cotonou',
      'district': 'Fidjrossè',
      'code': 'K7F-29X',
      'photos': <String>[],
      'active_rental': {
        'id': 'rental-1',
        'tenant_id': 'locataire-1',
        'tenant': {
          'id': 'locataire-1',
          'nom': 'Agossa',
          'prenoms': 'Patrick',
          'telephone': '0197123456',
        },
        'started_at': '2026-03-01T00:00:00Z',
        'status': 'ACTIVE',
      },
    },
    {
      'id': 'housing-2',
      'owner_id': 'proprio@lofi.bj',
      'title': 'Appartement 2B',
      'type': 'HOUSE',
      'rent': 350000,
      'due_day': 5,
      'city': 'Cotonou',
      'district': 'Fidjrossè',
      'code': 'M4T-83P',
      'photos': <String>[],
      'active_rental': {
        'id': 'rental-2',
        'tenant_id': 'locataire-2',
        'tenant': {
          'id': 'locataire-2',
          'nom': 'Dossou',
          'prenoms': 'Marceline',
          'telephone': '0197654321',
        },
        'started_at': '2026-03-01T00:00:00Z',
        'status': 'ACTIVE',
      },
    },
    {
      'id': 'housing-3',
      'owner_id': 'proprio@lofi.bj',
      'title': 'Appartement 3C',
      'type': 'HOUSE',
      'rent': 120000,
      'due_day': 5,
      'city': 'Cotonou',
      'district': 'Fidjrossè',
      'code': 'S9L-41Q',
      'photos': <String>[],
      'active_rental': {
        'id': 'rental-3',
        'tenant_id': 'locataire-3',
        'tenant': {
          'id': 'locataire-3',
          'nom': 'Bio-Tchané',
          'prenoms': 'Éric',
          'telephone': '0197001122',
        },
        'started_at': '2026-04-01T00:00:00Z',
        'status': 'ACTIVE',
      },
    },
    {
      'id': 'housing-4',
      'owner_id': 'proprio@lofi.bj',
      'title': 'Villa 4 pièces',
      'type': 'HOUSE',
      'rent': 200000,
      'due_day': 10,
      'city': 'Abomey-Calavi',
      'district': 'Togoudo',
      'code': 'V4C-902',
      'photos': <String>[],
      'active_rental': null,
    },
    {
      'id': 'housing-5',
      'owner_id': 'proprio@lofi.bj',
      'title': 'Studio',
      'type': 'ROOM',
      'rent': 60000,
      'due_day': 1,
      'city': 'Abomey-Calavi',
      'district': 'Togoudo',
      'code': 'STU-114',
      'photos': <String>[],
      'active_rental': null,
    },
  ];

  @override
  Future<Map<String, dynamic>> list() async {
    await Future<void>.delayed(_delay);
    return {'data': _storage};
  }

  @override
  Future<Map<String, dynamic>> detail(String id) async {
    await Future<void>.delayed(_delay);
    final item = _storage.cast<Map<String, dynamic>?>().firstWhere(
      (h) => h?['id'] == id,
      orElse: () => null,
    );
    if (item == null) {
      throw const ServerException('Ressource introuvable.');
    }
    return {'data': item};
  }

  @override
  Future<Map<String, dynamic>> create({
    required String title,
    required String type,
    required int rent,
    required int dueDay,
    required String city,
    required String district,
    List<String>? photos,
  }) async {
    await Future<void>.delayed(_delay);
    final randomSuffix = (100 + _storage.length).toString();
    final newHousing = {
      'id': 'housing-mock-$randomSuffix',
      'owner_id': 'proprio@lofi.bj',
      'title': title,
      'type': type,
      'rent': rent,
      'due_day': dueDay,
      'city': city,
      'district': district,
      'code': 'LOF-$randomSuffix',
      'photos': photos ?? <String>[],
      'active_rental': null,
    };
    _storage.insert(0, newHousing);
    return {'data': newHousing};
  }

  @override
  Future<Map<String, dynamic>> update(
    String id, {
    String? title,
    int? rent,
    int? dueDay,
    String? city,
    String? district,
  }) async {
    await Future<void>.delayed(_delay);
    final index = _storage.indexWhere((h) => h['id'] == id);
    if (index == -1) throw const ServerException('Logement introuvable.');

    final current = _storage[index];
    if (title != null) current['title'] = title;
    if (rent != null) current['rent'] = rent;
    if (dueDay != null) current['due_day'] = dueDay;
    if (city != null) current['city'] = city;
    if (district != null) current['district'] = district;

    return {'data': current};
  }

  @override
  Future<Map<String, dynamic>> endRental(String rentalId) async {
    await Future<void>.delayed(_delay);
    for (final housing in _storage) {
      if (housing['active_rental']?['id'] == rentalId) {
        housing['active_rental'] = null;
        return {'message': 'Location terminée.'};
      }
    }
    return {'message': 'Location terminée.'};
  }
}
