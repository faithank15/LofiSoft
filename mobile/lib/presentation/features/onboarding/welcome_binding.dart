import 'package:get/get.dart';
import 'welcome_controller.dart';

/// Injection des dépendances de l'écran d'accueil E1.
class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WelcomeController>(() => WelcomeController());
  }
}
