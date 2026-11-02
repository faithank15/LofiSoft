import '../../core/errors/app_exception.dart';
import '../../domain/models/enums.dart';
import '../remote/services/announcement_service.dart';
import '../remote/services/upload_service.dart';

/// Ce que le propriétaire saisit pour une nouvelle annonce (écrans C3 et C4).
class NewAnnouncement {
  const NewAnnouncement({
    required this.title,
    required this.type,
    required this.rent,
    required this.depositMonths,
    required this.city,
    required this.district,
    required this.rooms,
    this.housingId,
    this.description,
  });

  final String? housingId;
  final String title;
  final AccommodationType type;
  final int rent;
  final int depositMonths;
  final String city;
  final String district;
  final int rooms;
  final String? description;

  Map<String, dynamic> toJson(List<String> photoUrls) => {
        'housing_id': ?housingId,
        'title': title,
        'type': type.name,
        'rent': rent,
        'deposit_months': depositMonths,
        'city': city,
        'district': district,
        'rooms': rooms,
        if ((description ?? '').trim().isNotEmpty) 'description': description!.trim(),
        if (photoUrls.isNotEmpty) 'photos': photoUrls,
      };
}

/// Publication d'une annonce par le propriétaire : envoi des photos, création, publication.
class OwnerAnnouncementRepository {
  OwnerAnnouncementRepository(this._announcements, this._uploads);

  final AnnouncementService _announcements;
  final UploadService _uploads;

  /// Envoie les photos (dans l'ordre), crée l'annonce puis la publie. Renvoie son identifiant.
  ///
  /// Si la publication échoue après la création, l'annonce reste en brouillon côté serveur
  /// et l'erreur est relancée.
  Future<String> publish(NewAnnouncement announcement, {List<String> photoPaths = const []}) async {
    final urls = <String>[];
    for (final path in photoPaths) {
      final json = await _uploads.upload(filePath: path, kind: 'announcement_photo');
      final url = json['url'];
      if (url is! String || url.isEmpty) {
        throw const ServerException("L'envoi d'une photo a échoué.");
      }
      urls.add(url);
    }

    final created = await _announcements.create(announcement.toJson(urls));
    final id = '${created['id'] ?? ''}';
    if (id.isEmpty) throw const ServerException('Réponse inattendue du serveur (annonce sans identifiant).');

    await _announcements.publish(id);
    return id;
  }
}
