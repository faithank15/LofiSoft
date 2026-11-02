import '../../core/utils/json_utils.dart';
import 'enums.dart';

DateTime? _date(Object? raw) => DateTime.tryParse('${raw ?? ''}')?.toLocal();

int _int(Object? v) => v is num ? v.round() : int.tryParse('${v ?? ''}') ?? 0;

String? _text(Object? v) {
  final s = '${v ?? ''}'.trim();
  return s.isEmpty ? null : s;
}

/// Un signalement (une ligne de GET /admin/reports).
class ReportItem {
  const ReportItem({
    required this.id,
    required this.reason,
    required this.announcementId,
    required this.announcementTitle,
    required this.reportsCount,
    this.details,
    this.status = ReportStatus.PENDING,
    this.createdAt,
    this.city,
    this.ownerName,
  });

  final String id;
  final String reason;
  final String? details;
  final ReportStatus status;
  final DateTime? createdAt;
  final String announcementId;
  final String announcementTitle;
  final String? city;
  final String? ownerName;

  /// Nombre total de signalements visant cette annonce.
  final int reportsCount;

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    final ann = asJsonMap(json['announcement']);
    return ReportItem(
      id: '${json['id'] ?? ''}',
      reason: _text(json['reason']) ?? 'Signalement',
      details: _text(json['details']),
      status: _status(json['status']),
      createdAt: _date(json['created_at']),
      announcementId: '${ann['id'] ?? ''}',
      announcementTitle: _text(ann['title']) ?? 'Annonce supprimée',
      city: _text(ann['city']),
      ownerName: _text(ann['owner_name']),
      reportsCount: _int(json['reports_count']),
    );
  }

  static ReportStatus _status(Object? raw) {
    final val = '${raw ?? ''}'.toUpperCase();
    for (final s in ReportStatus.values) {
      if (s.name == val) return s;
    }
    return ReportStatus.PENDING;
  }
}

/// Tous les signalements d'une même annonce, affichés sur UNE carte (maquette D1).
class ReportGroup {
  const ReportGroup({required this.reports});

  /// Du plus récent au plus ancien. Jamais vide.
  final List<ReportItem> reports;

  ReportItem get latest => reports.first;

  String get announcementId => latest.announcementId;

  /// Motif du signalement le plus récent.
  String get reason => latest.reason;

  DateTime? get createdAt => latest.createdAt;

  /// « Villa 4 pièces, Calavi »
  String get headline =>
      latest.city == null ? latest.announcementTitle : '${latest.announcementTitle}, ${latest.city}';

  /// Nombre de signalements : le plus grand de ce que dit le serveur et de ce qu'on a reçu.
  int get count {
    final server = reports.map((r) => r.reportsCount).fold<int>(0, (a, b) => a > b ? a : b);
    return server > reports.length ? server : reports.length;
  }

  /// « Propriétaire : Koffi Mensah · 2 signalements »
  String get subtitle {
    final owner = latest.ownerName;
    final n = '$count signalement${count > 1 ? 's' : ''}';
    return owner == null ? n : 'Propriétaire : $owner · $n';
  }

  /// Regroupe par annonce. Le groupe le plus récent vient en premier.
  static List<ReportGroup> from(Iterable<ReportItem> items) {
    final byAnnouncement = <String, List<ReportItem>>{};
    for (final r in items) {
      byAnnouncement.putIfAbsent(r.announcementId, () => []).add(r);
    }
    final groups = [
      for (final list in byAnnouncement.values)
        ReportGroup(reports: [...list]..sort(_newestFirst)),
    ]..sort((a, b) => _newestFirst(a.latest, b.latest));
    return groups;
  }

  static int _newestFirst(ReportItem a, ReportItem b) {
    final da = a.createdAt, db = b.createdAt;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  }
}

/// Une demande de badge « Vérifié » (une ligne de GET /admin/identity-requests).
class IdentityRequestItem {
  const IdentityRequestItem({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.housingsCount = 0,
    this.idImageUrl,
    this.selfieUrl,
    this.status = IdentityStatus.PENDING,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final int housingsCount;
  final String? idImageUrl;
  final String? selfieUrl;
  final IdentityStatus status;
  final DateTime? createdAt;

  /// « AS » pour « Awa Sanni »
  String get initials {
    final parts = ownerName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// « 1 logement » / « 2 logements » / « Aucun logement »
  String get housingsLabel => switch (housingsCount) {
        0 => 'Aucun logement',
        1 => '1 logement',
        final n => '$n logements',
      };

  factory IdentityRequestItem.fromJson(Map<String, dynamic> json) {
    final owner = asJsonMap(json['owner']);
    return IdentityRequestItem(
      id: '${json['id'] ?? ''}',
      ownerId: '${owner['id'] ?? ''}',
      ownerName: _text(owner['name']) ?? 'Propriétaire',
      housingsCount: _int(owner['housings_count']),
      idImageUrl: _text(json['id_image_url']),
      selfieUrl: _text(json['selfie_url']),
      status: _status(json['status']),
      createdAt: _date(json['created_at']),
    );
  }

  static IdentityStatus _status(Object? raw) {
    final val = '${raw ?? ''}'.toUpperCase();
    for (final s in IdentityStatus.values) {
      if (s.name == val) return s;
    }
    return IdentityStatus.PENDING;
  }
}
