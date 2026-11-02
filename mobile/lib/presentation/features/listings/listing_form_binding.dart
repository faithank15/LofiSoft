import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_announcement_service.dart';
import '../../../data/remote/fakes/fake_property_service.dart';
import '../../../data/remote/fakes/fake_upload_service.dart';
import '../../../data/remote/services/announcement_service.dart';
import '../../../data/remote/services/property_service.dart';
import '../../../data/remote/services/upload_service.dart';
import '../../../data/repo/owner_announcement_repository.dart';
import '../../../data/repo/property_repository.dart';
import 'listing_form_controller.dart';

/// Injection de la création d'annonce (C3 et C4). ApiClient et AppStorage sont déjà enregistrés.
class ListingFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnnouncementService>(
      () => AppConfig.useFakeApi ? FakeAnnouncementService(Get.find()) : AnnouncementService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<UploadService>(
      () => AppConfig.useFakeApi ? FakeUploadService(Get.find()) : UploadService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<PropertyService>(
      () => AppConfig.useFakeApi ? FakePropertyService(Get.find()) : PropertyService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<PropertyRepository>(() => PropertyRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut<OwnerAnnouncementRepository>(
      () => OwnerAnnouncementRepository(Get.find(), Get.find()),
      fenix: true,
    );
    Get.lazyPut<ListingFormController>(
      () => ListingFormController(repository: Get.find(), properties: Get.find()),
    );
  }
}
