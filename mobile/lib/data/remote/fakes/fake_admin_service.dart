import '../../../core/errors/app_exception.dart';
import '../services/admin_service.dart';

/// Service simulé de l'espace administrateur (`USE_FAKE_API=true`).
/// Garde l'état en mémoire : une carte traitée ne revient pas au rechargement.
class FakeAdminService extends AdminService {
  FakeAdminService(super.api);

  static const _delay = Duration(milliseconds: 400);

  static String _ago(Duration d) => DateTime.now().subtract(d).toUtc().toIso8601String();

  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'rep-1', 'reason': 'Annonce frauduleuse', 'details': null, 'status': 'PENDING',
      'created_at': _ago(const Duration(hours: 2)), 'reports_count': 2,
      'announcement': {'id': 'ann-1', 'title': 'Villa 4 pièces', 'city': 'Calavi', 'owner_name': 'Koffi Mensah'},
    },
    {
      'id': 'rep-1b', 'reason': 'Prix suspect', 'details': null, 'status': 'PENDING',
      'created_at': _ago(const Duration(hours: 9)), 'reports_count': 2,
      'announcement': {'id': 'ann-1', 'title': 'Villa 4 pièces', 'city': 'Calavi', 'owner_name': 'Koffi Mensah'},
    },
    {
      'id': 'rep-2', 'reason': 'Photo non conforme', 'details': null, 'status': 'PENDING',
      'created_at': _ago(const Duration(days: 1)), 'reports_count': 1,
      'announcement': {'id': 'ann-2', 'title': 'Studio meublé', 'city': 'Cotonou', 'owner_name': 'Awa Sanni'},
    },
    {
      'id': 'rep-3', 'reason': 'Logement déjà loué', 'details': null, 'status': 'PENDING',
      'created_at': _ago(const Duration(days: 3)), 'reports_count': 1,
      'announcement': {'id': 'ann-3', 'title': 'Chambre-salon', 'city': 'Porto-Novo', 'owner_name': 'Jean Hounkpatin'},
    },
  ];

  final List<Map<String, dynamic>> _identities = [
    {
      'id': 'idr-1', 'status': 'PENDING', 'created_at': _ago(const Duration(days: 1)),
      'id_image_url': null, 'selfie_url': null,
      'owner': {'id': 'own-1', 'name': 'Awa Sanni', 'housings_count': 1},
    },
    {
      'id': 'idr-2', 'status': 'PENDING', 'created_at': _ago(const Duration(days: 3)),
      'id_image_url': null, 'selfie_url': null,
      'owner': {'id': 'own-2', 'name': 'Jean Hounkpatin', 'housings_count': 2},
    },
  ];

  @override
  Future<Map<String, dynamic>> reports({String status = 'PENDING'}) async {
    await Future<void>.delayed(_delay);
    return {'data': _reports.where((r) => r['status'] == status).toList()};
  }

  @override
  Future<Map<String, dynamic>> resolveReport(String id, {required String action}) async {
    await Future<void>.delayed(_delay);
    final report = _find(_reports, id, 'Signalement introuvable.');
    report['status'] = 'RESOLVED';
    return {'message': 'Signalement résolu.'};
  }

  @override
  Future<Map<String, dynamic>> dismissReport(String id) async {
    await Future<void>.delayed(_delay);
    _find(_reports, id, 'Signalement introuvable.')['status'] = 'DISMISSED';
    return {'message': 'Signalement ignoré.'};
  }

  @override
  Future<Map<String, dynamic>> identityRequests({String status = 'PENDING'}) async {
    await Future<void>.delayed(_delay);
    return {'data': _identities.where((r) => r['status'] == status).toList()};
  }

  @override
  Future<Map<String, dynamic>> approveIdentity(String id) async {
    await Future<void>.delayed(_delay);
    _find(_identities, id, 'Demande introuvable.')['status'] = 'APPROVED';
    return {'message': 'Propriétaire certifié avec succès.'};
  }

  @override
  Future<Map<String, dynamic>> rejectIdentity(String id, {required String reason}) async {
    await Future<void>.delayed(_delay);
    _find(_identities, id, 'Demande introuvable.')['status'] = 'REJECTED';
    return {'message': 'Demande rejetée.'};
  }

  final List<Map<String, dynamic>> _users = [
    {'id': 'u-1', 'nom': 'Agossa', 'prenoms': 'Patrick', 'email': 'locataire@lofi.bj', 'telephone': '0197123456', 'role': 'TENANT', 'actif': true, 'identity_verified': false},
    {'id': 'u-2', 'nom': 'Hounkpatin', 'prenoms': 'Rose', 'email': 'locataire2@lofi.bj', 'telephone': '0197123457', 'role': 'TENANT', 'actif': true, 'identity_verified': false},
    {'id': 'u-3', 'nom': 'Mensah', 'prenoms': 'Koffi', 'email': 'proprio@lofi.bj', 'telephone': '0197000001', 'role': 'OWNER', 'actif': true, 'identity_verified': true},
    {'id': 'u-4', 'nom': 'Sanni', 'prenoms': 'Awa', 'email': 'admin@lofi.bj', 'telephone': '0197000003', 'role': 'ADMIN', 'actif': true, 'identity_verified': false},
  ];

  @override
  Future<Map<String, dynamic>> users({String? role, String? query, int perPage = 50}) async {
    await Future<void>.delayed(_delay);
    final q = (query ?? '').trim().toLowerCase();
    final rows = _users.where((u) {
      if (role != null && u['role'] != role) return false;
      return q.isEmpty || '${u['nom']} ${u['prenoms']} ${u['email']}'.toLowerCase().contains(q);
    }).toList();
    return {'data': rows, 'meta': {'current_page': 1, 'last_page': 1, 'total': rows.length}};
  }

  @override
  Future<Map<String, dynamic>> setUserActive(String id, {required bool actif}) async {
    await Future<void>.delayed(_delay);
    final user = _find(_users, id, 'Utilisateur introuvable.');
    if (user['role'] == 'ADMIN' && !actif) {
      throw const ValidationException('Vous ne pouvez pas suspendre votre propre compte.');
    }
    user['actif'] = actif;
    return {'message': 'Statut du compte mis à jour.'};
  }

  Map<String, dynamic> _find(List<Map<String, dynamic>> list, String id, String notFound) {
    for (final item in list) {
      if (item['id'] == id) return item;
    }
    throw ServerException(notFound);
  }
}
