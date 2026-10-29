import '../../core/errors/app_exception.dart';
import '../remote/services/auth_service.dart';
import '../remote/services/upload_service.dart';

/// Vérification d'identité du propriétaire (badge « Vérifié »).
/// Téléverse la pièce et le selfie, puis envoie leurs URL pour validation par l'admin.
class IdentityRepository {
  IdentityRepository(this._uploads, this._auth);

  final UploadService _uploads;
  final AuthService _auth;

  Future<void> submit({required String idImagePath, required String selfiePath}) async {
    final idUrl = await _upload(idImagePath, 'identity_id');
    final selfieUrl = await _upload(selfiePath, 'identity_selfie');
    await _auth.submitIdentity(idImageUrl: idUrl, selfieUrl: selfieUrl);
  }

  Future<String> _upload(String path, String kind) async {
    final json = await _uploads.upload(filePath: path, kind: kind);
    final url = json['url'];
    if (url is! String || url.isEmpty) {
      throw const ServerException("L'envoi de l'image a échoué.");
    }
    return url;
  }
}
