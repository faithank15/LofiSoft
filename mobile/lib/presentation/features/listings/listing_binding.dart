import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_announcement_service.dart';
import '../../../data/remote/services/announcement_service.dart';
import '../../../data/repo/announcement_repository.dart';
import 'listing_details_controller.dart';
import 'listings_controller.dart';

/// Binding du fil (A1) et des favoris (A4). Le service est faux avec USE_FAKE_API.
class ListingBinding extends Bindings {
  @override
  void dependencies() {
    _registerData();
    Get.lazyPut<ListingsController>(
      () => ListingsController(
        repository: Get.find(),
        authStorage: Get.find(),
        appStorage: Get.find(),
      ),
    );
  }
}

/// Binding du détail d'une annonce (A3).
class ListingDetailsBinding extends Bindings {
  @override
  void dependencies() {
    _registerData();
    Get.lazyPut<ListingDetailsController>(
      () => ListingDetailsController(repository: Get.find(), authStorage: Get.find()),
    );
  }
}

void _registerData() {
  Get.lazyPut<AnnouncementService>(
    () => AppConfig.useFakeApi ? FakeAnnouncementService(Get.find()) : AnnouncementService(Get.find()),
    fenix: true,
  );
  Get.lazyPut<AnnouncementRepository>(() => AnnouncementRepository(Get.find()), fenix: true);
}
