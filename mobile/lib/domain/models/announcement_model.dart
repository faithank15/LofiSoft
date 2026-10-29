import '../../core/utils/json_utils.dart';
import 'enums.dart';

/// Annonce telle que l'API la renvoie (fil, détail, favoris).
/// `description`, `ownerId` et `ownerName` ne sont remplis que par le détail.
class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.type,
    required this.rent,
    required this.city,
    required this.district,
    this.depositMonths = 0,
    this.rooms = 1,
    this.photos = const [],
    this.verified = false,
    this.isFavorite = false,
    this.status = AnnouncementStatus.PUBLISHED,
    this.publishedAt,
    this.description = '',
    this.ownerId = '',
    this.ownerName = '',
  });

  final String id;
  final String title;
  final AccommodationType type;

  /// Loyer mensuel en FCFA.
  final int rent;
  final int depositMonths;
  final String city;
  final String district;
  final int rooms;
  final List<String> photos;

  /// Le propriétaire a passé la vérification d'identité.
  final bool verified;
  final bool isFavorite;
  final AnnouncementStatus status;
  final DateTime? publishedAt;
  final String description;
  final String ownerId;
  final String ownerName;

  /// « Fidjrossè, Cotonou »
  String get location => [district, city].where((s) => s.trim().isNotEmpty).join(', ');

  String? get firstPhoto => photos.isEmpty ? null : photos.first;

  AnnouncementModel copyWith({bool? isFavorite}) => AnnouncementModel(
        id: id,
        title: title,
        type: type,
        rent: rent,
        city: city,
        district: district,
        depositMonths: depositMonths,
        rooms: rooms,
        photos: photos,
        verified: verified,
        isFavorite: isFavorite ?? this.isFavorite,
        status: status,
        publishedAt: publishedAt,
        description: description,
        ownerId: ownerId,
        ownerName: ownerName,
      );

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final owner = asJsonMap(json['owner']);
    return AnnouncementModel(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      type: _enum(AccommodationType.values, json['type'], AccommodationType.OTHER),
      rent: _int(json['rent']),
      depositMonths: _int(json['deposit_months']),
      city: '${json['city'] ?? ''}',
      district: '${json['district'] ?? ''}',
      rooms: _int(json['rooms'], 1),
      photos: asJsonList(json['photos']).whereType<String>().toList(),
      verified: json['verified'] == true,
      isFavorite: json['is_favorite'] == true,
      status: _enum(AnnouncementStatus.values, json['status'], AnnouncementStatus.PUBLISHED),
      publishedAt: DateTime.tryParse('${json['published_at'] ?? ''}'),
      description: '${json['description'] ?? ''}',
      ownerId: '${owner['id'] ?? ''}',
      ownerName: '${owner['name'] ?? ''}',
    );
  }

  static int _int(Object? v, [int fallback = 0]) =>
      v is num ? v.round() : int.tryParse('${v ?? ''}') ?? fallback;

  static T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }
}

/// Page d'annonces du fil.
class AnnouncementPage {
  const AnnouncementPage({required this.items, required this.currentPage, required this.lastPage});

  final List<AnnouncementModel> items;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}
