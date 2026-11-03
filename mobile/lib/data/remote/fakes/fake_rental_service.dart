import '../../../core/errors/app_exception.dart';
import '../services/rental_service.dart';
import 'fake_payment_service.dart';

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
    _reads = 0;
    _phase = 'PENDING';
    return {
      'message': 'Demande envoyée au propriétaire.',
      'rental': {'id': '3', 'status': 'PENDING'},
    };
  }

  // Parcours simulé : aucune location -> (code saisi) demande en attente -> acceptée -> active.
  // Le propriétaire « accepte » après deux lectures de la situation (tirer pour actualiser).
  static String _phase = 'NONE';
  static int _reads = 0;

  /// Force une location active (menu de dev) : les écrans de loyer et de
  /// paiement affichent des valeurs cohérentes sans passer par le parcours.
  static void devActive() {
    _phase = 'ACTIVE';
    _reads = 0;
  }

  @override
  Future<Map<String, dynamic>> situation() async {
    await Future<void>.delayed(_delay);
    if (_phase == 'PENDING' && ++_reads > 1) _phase = 'ACTIVE';
    if (_phase == 'NONE') return {'status': 'NONE'};
    return {
      'status': _phase,
      'rental_id': '3',
      'housing': {
        'id': '3',
        'title': 'Appartement 1A',
        'city': 'Cotonou',
        'district': 'Fidjrossè',
        'rent': 150000,
        'due_day': 5,
      },
      'owner': {'name': 'Koffi Mensah', 'telephone': '0197000002'},
    };
  }

  @override
  Future<Map<String, dynamic>> currentRent() async {
    await Future<void>.delayed(_delay);
    final now = DateTime.now();
    final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    // Les paiements réussis de la période réduisent le reste à payer.
    const total = 150000;
    final paid = 90000 + FakePaymentService.successfulAmount(period);
    final remaining = (total - paid).clamp(0, total);
    return {
      'period': period,
      'total': total,
      'paid': paid,
      'remaining': remaining,
      'due_date': DateTime(now.year, now.month, 5).toIso8601String().substring(0, 10),
      'status': remaining == 0 ? 'PAID' : (paid == 0 ? 'UNPAID' : 'PARTIAL'),
    };
  }

  @override
  Future<Map<String, dynamic>> payments() async {
    await Future<void>.delayed(_delay);
    final now = DateTime.now();
    String period(int back) {
      final d = DateTime(now.year, now.month - back);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    }

    return {
      'data': [
        {'id': 'p1', 'amount': 40000, 'operator': 'MTN', 'paid_at': now.subtract(const Duration(days: 4)).toUtc().toIso8601String(), 'period': period(0), 'status': 'SUCCESS'},
        {'id': 'p2', 'amount': 50000, 'operator': 'MTN', 'paid_at': now.subtract(const Duration(days: 9)).toUtc().toIso8601String(), 'period': period(0), 'status': 'SUCCESS'},
        {'id': 'p3', 'amount': 150000, 'operator': 'MOOV', 'paid_at': now.subtract(const Duration(days: 35)).toUtc().toIso8601String(), 'period': period(1), 'status': 'SUCCESS'},
      ],
    };
  }
}
