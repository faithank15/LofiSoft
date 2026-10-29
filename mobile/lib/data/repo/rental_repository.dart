import '../../domain/models/rental_model.dart';
import '../remote/services/rental_service.dart';

/// Source de vérité du code logement et de la location du locataire.
class RentalRepository {
  RentalRepository(this._service);

  final RentalService _service;

  Future<HousingPreview> lookup(String code) async =>
      HousingPreview.fromJson(await _service.lookup(code));

  Future<void> join(String code) async {
    await _service.join(code);
  }
}
