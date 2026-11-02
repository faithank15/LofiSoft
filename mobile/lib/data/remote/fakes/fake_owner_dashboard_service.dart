import '../services/owner_dashboard_service.dart';

/// FAUX service du tableau de bord propriétaire (USE_FAKE_API=true).
/// Les données reprennent les maquettes C1 et C7.
class FakeOwnerDashboardService extends OwnerDashboardService {
  FakeOwnerDashboardService(super.api);

  static const _delay = Duration(milliseconds: 500);

  @override
  Future<Map<String, dynamic>> dashboard() async {
    await Future<void>.delayed(_delay);
    return {
      'month': '2026-11',
      'expected': 649900,
      'received': 426800,
      'late_count': 1,
      'tenants_count': 3,
      'housings_count': 5,
    };
  }

  @override
  Future<Map<String, dynamic>> tenants() async {
    await Future<void>.delayed(_delay);
    return {
      'data': [
        {
          'rental_id': 'rental-2',
          'tenant_name': 'Marceline Dossou',
          'housing': 'Appartement 2B',
          'due': 350000,
          'carried_over': 0,
          'paid': 350000,
          'status': 'PAID',
        },
        {
          'rental_id': 'rental-1',
          'tenant_name': 'Patrick Agossa',
          'housing': 'Appartement 1A',
          'due': 150000,
          'carried_over': 0,
          'paid': 90000,
          'status': 'PARTIAL',
        },
        {
          'rental_id': 'rental-3',
          'tenant_name': 'Éric Bio-Tchané',
          'housing': 'Appartement 3C',
          'due': 170000,
          'carried_over': 50000,
          'paid': 0,
          'status': 'LATE',
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> remind(String rentalId) async {
    await Future<void>.delayed(_delay);
    return {'message': 'Rappel envoyé au locataire.'};
  }
}