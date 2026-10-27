import 'package:get/get.dart';

import 'listings_controller.dart';

class ListingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ListingsController>()) {
      Get.put<ListingsController>(ListingsController(), permanent: true);
    }
  }
}