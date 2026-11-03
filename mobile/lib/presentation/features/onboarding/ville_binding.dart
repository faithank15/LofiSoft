import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_geolocation_service.dart';
import '../../../data/remote/services/geolocation_service.dart';
import '../../../data/repo/geolocation_repository.dart';
import 'ville_controller.dart';

/// Injection des dépendances de l'écran E2.
class VilleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GeolocationService>(
      () => AppConfig.useFakeApi ? FakeGeolocationService() : GeolocationService(),
    );
    Get.lazyPut<GeolocationRepository>(
      () => GeolocationRepository(Get.find<GeolocationService>()),
    );
    Get.lazyPut<VilleController>(
      () => VilleController(geolocationRepository: Get.find<GeolocationRepository>()),
    );
  }
}
