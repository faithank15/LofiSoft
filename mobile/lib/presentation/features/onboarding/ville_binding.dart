import 'package:get/get.dart';
import 'ville_controller.dart';

/// Injection des dépendances de l'écran E2.
class VilleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VilleController>(() => VilleController());
  }
}
