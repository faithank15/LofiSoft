import 'package:get/get.dart';
import 'type_controller.dart';

/// Injection des dépendances de l'écran E3.
class TypeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TypeController>(() => TypeController());
  }
}
