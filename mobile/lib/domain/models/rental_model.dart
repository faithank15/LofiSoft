import '../../core/utils/json_utils.dart';

/// Logement retrouvé grâce à son code, avant que le locataire confirme (écran B1).
/// `dueDay` et `ownerVerified` sont facultatifs : l'API de base ne les renvoie pas encore.
class HousingPreview {
  const HousingPreview({
    required this.id,
    required this.title,
    required this.city,
    required this.district,
    required this.rent,
    required this.ownerName,
    this.dueDay,
    this.ownerVerified = false,
  });

  final String id;
  final String title;
  final String city;
  final String district;
  final int rent;
  final String ownerName;
  final int? dueDay;
  final bool ownerVerified;

  String get location => [district, city].where((s) => s.trim().isNotEmpty).join(', ');

  factory HousingPreview.fromJson(Map<String, dynamic> json) {
    final h = asJsonMap(json['housing'] ?? json['data'] ?? json);
    final rent = h['rent'];
    final due = h['due_day'];
    return HousingPreview(
      id: '${h['id'] ?? ''}',
      title: '${h['title'] ?? ''}',
      city: '${h['city'] ?? ''}',
      district: '${h['district'] ?? ''}',
      rent: rent is num ? rent.round() : int.tryParse('${rent ?? ''}') ?? 0,
      ownerName: '${h['owner_name'] ?? ''}',
      dueDay: due is num ? due.round() : int.tryParse('${due ?? ''}'),
      ownerVerified: h['owner_verified'] == true,
    );
  }
}
