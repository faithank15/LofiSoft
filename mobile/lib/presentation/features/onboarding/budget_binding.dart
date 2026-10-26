import 'package:get/get.dart';
import 'budget_controller.dart';

/// Injection des dépendances de l'écran E4.
class BudgetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BudgetController>(() => BudgetController());
  }
}
