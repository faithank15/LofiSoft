import 'package:get/get.dart';

import 'rent_tracking_controller.dart';

class RentTrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentTrackingController>(() => RentTrackingController());
  }
}