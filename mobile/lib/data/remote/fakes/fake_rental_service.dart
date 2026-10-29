import '../../../core/errors/app_exception.dart';
import '../services/rental_service.dart';

/// FAUX service de location, pour développer sans API.
/// Codes de test : `M4T-83P` (logement trouvé), `JOI-N00` (déjà une location -> erreur 409).
/// Tout autre code : « Ce code ne correspond à aucun logement. »
class FakeRentalService extends RentalService {
  FakeRentalService(super.api);

  static const _delay = Duration(milliseconds: 600);

  @override
  Future<Map<String, dynamic>> lookup(String code) async {
    await Future<void>.delayed(_delay);
    if (code != 'M4T-83P' && code != 'JOI-N00') {
      throw const ServerException('Ce code ne correspond à aucun logement.');
    }
    return {
      'housing': {
        'id': '3',
        'title': 'Appartement 1A',
        'city': 'Cotonou',
        'district': 'Fidjrossè',
        'rent': 150000,
        'owner_name': 'Koffi Mensah',
        'due_day': 5,
        'owner_verified': true,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> join(String code) async {
    await Future<void>.delayed(_delay);
    if (code == 'JOI-N00') {
      throw const ServerException('Vous avez déjà une location active ou en attente.');
    }
    return {
      'message': 'Demande envoyée au propriétaire.',
      'rental': {'id': '3', 'status': 'PENDING'},
    };
  }
}
