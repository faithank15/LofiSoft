import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_property_service.dart';
import '../../../data/remote/services/property_service.dart';
import '../../../data/repo/property_repository.dart';
import 'property_controller.dart';

/// Injection des dépendances du Lot 8 (Logements propriétaire).
class PropertyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertyService>(
      () => AppConfig.useFakeApi
          ? FakePropertyService(Get.find())
          : PropertyService(Get.find()),
      fenix: true,
    );

    Get.lazyPut<PropertyRepository>(
      () => PropertyRepository(Get.find(), Get.find()),
      fenix: true,
    );

    Get.lazyPut<PropertyController>(
      () => PropertyController(repository: Get.find()),
    );
  }
}
