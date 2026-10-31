import '../../core/utils/json_utils.dart';
import 'enums.dart';

/// Détails d'une location active liée à un logement.
class ActiveRentalModel {
  const ActiveRentalModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
    this.startedAt,
    this.status = RentalStatus.ACTIVE,
  });

  final String id;
  final String tenantId;
  final String tenantName;
  final String tenantPhone;
  final DateTime? startedAt;
  final RentalStatus status;

  bool get isActive => status == RentalStatus.ACTIVE;

  factory ActiveRentalModel.fromJson(Map<String, dynamic> json) {
    final tenant = asJsonMap(json['tenant']);
    final prenom = '${tenant['prenoms'] ?? ''}'.trim();
    final nom = '${tenant['nom'] ?? ''}'.trim();
    final fullName = [prenom, nom].where((s) => s.isNotEmpty).join(' ');

    return ActiveRentalModel(
      id: '${json['id'] ?? ''}',
      tenantId: '${json['tenant_id'] ?? tenant['id'] ?? ''}',
      tenantName: fullName.isNotEmpty
          ? fullName
          : '${tenant['name'] ?? 'Locataire'}',
      tenantPhone: '${tenant['telephone'] ?? ''}',
      startedAt: DateTime.tryParse('${json['started_at'] ?? ''}'),
      status: _parseRentalStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'tenant': {'id': tenantId, 'name': tenantName, 'telephone': tenantPhone},
    'started_at': startedAt?.toIso8601String(),
    'status': status.name,
  };

  static RentalStatus _parseRentalStatus(Object? raw) {
    final val = '${raw ?? ''}'.toUpperCase();
    for (final s in RentalStatus.values) {
      if (s.name == val) return s;
    }
    return RentalStatus.ACTIVE;
  }
}

/// Modèle officiel d'un logement propriétaire (aligné sur la table 'housings' Laravel).
class HousingModel {
  const HousingModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.type,
    required this.rent,
    required this.dueDay,
    required this.city,
    required this.district,
    required this.code,
    this.photos = const [],
    this.activeRental,
  });

  final String id;
  final String ownerId;
  final String title;
  final AccommodationType type;
  final int rent;
  final int dueDay;
  final String city;
  final String district;
  final String code;
  final List<String> photos;
  final ActiveRentalModel? activeRental;

  bool get isRented => activeRental != null && activeRental!.isActive;

  String get location =>
      [district, city].where((s) => s.trim().isNotEmpty).join(', ');

  String get statusLabel => isRented ? 'Loué' : 'Libre';

  HousingModel copyWith({
    String? title,
    AccommodationType? type,
    int? rent,
    int? dueDay,
    String? city,
    String? district,
    List<String>? photos,
    ActiveRentalModel? activeRental,
    bool clearActiveRental = false,
  }) {
    return HousingModel(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      type: type ?? this.type,
      rent: rent ?? this.rent,
      dueDay: dueDay ?? this.dueDay,
      city: city ?? this.city,
      district: district ?? this.district,
      code: code,
      photos: photos ?? this.photos,
      activeRental: clearActiveRental
          ? null
          : (activeRental ?? this.activeRental),
    );
  }

  factory HousingModel.fromJson(Map<String, dynamic> json) {
    final rentalRaw = json['active_rental'] ?? json['activeRental'];
    return HousingModel(
      id: '${json['id'] ?? ''}',
      ownerId: '${json['owner_id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      type: _parseType(json['type']),
      rent: _parseInt(json['rent']),
      dueDay: _parseInt(json['due_day'], 5),
      city: '${json['city'] ?? ''}',
      district: '${json['district'] ?? ''}',
      code: '${json['code'] ?? ''}',
      photos: asJsonList(json['photos']).whereType<String>().toList(),
      activeRental: rentalRaw != null
          ? ActiveRentalModel.fromJson(asJsonMap(rentalRaw))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'title': title,
    'type': type.name,
    'rent': rent,
    'due_day': dueDay,
    'city': city,
    'district': district,
    'code': code,
    'photos': photos,
    if (activeRental != null) 'active_rental': activeRental!.toJson(),
  };

  static int _parseInt(Object? v, [int fallback = 0]) {
    if (v is num) return v.round();
    return int.tryParse('${v ?? ''}') ?? fallback;
  }

  static AccommodationType _parseType(Object? raw) {
    final val = '${raw ?? ''}'.toUpperCase();
    for (final t in AccommodationType.values) {
      if (t.name == val) return t;
    }
    return AccommodationType.HOUSE;
  }
}
