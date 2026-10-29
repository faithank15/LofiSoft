import '../services/upload_service.dart';

/// FAUX envoi d'image : ne contacte personne, renvoie une URL factice.
class FakeUploadService extends UploadService {
  FakeUploadService(super.api);

  @override
  Future<Map<String, dynamic>> upload({required String filePath, required String kind}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return {'url': 'https://example.com/fake/$kind.jpg'};
  }
}
