import 'package:get/get.dart';

import '../../../core/network/api_client.dart';

/// Envoi d'une image au serveur, qui renvoie son URL (`{ "url": "..." }`).
/// `kind` : announcement_photo, identity_id ou identity_selfie.
class UploadService extends GetxService {
  UploadService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> upload({required String filePath, required String kind}) =>
      _api.upload('/uploads', filePath: filePath, fields: {'kind': kind});
}
