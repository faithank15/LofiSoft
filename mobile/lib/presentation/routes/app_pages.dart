import 'package:get/get.dart';
import '../features/onboarding/welcome_binding.dart';
import '../features/onboarding/welcome_page.dart';
import '../features/onboarding/budget_binding.dart';
import '../features/onboarding/budget_page.dart';
import '../features/onboarding/type_binding.dart';
import '../features/onboarding/type_page.dart';
import '../features/onboarding/ville_binding.dart';
import '../features/onboarding/ville_page.dart';
import 'app_routes.dart';

/// Table liant chaque nom de route à sa page et à son binding dédié.
class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.welcome,
      page: () => const WelcomePage(),
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: AppRoutes.onboardingVille,
      page: () => const VillePage(),
      binding: VilleBinding(),
    ),
    GetPage(
      name: AppRoutes.onboardingType,
      page: () => const TypePage(),
      binding: TypeBinding(),
    ),
    GetPage(
      name: AppRoutes.onboardingBudget,
      page: () => const BudgetPage(),
      binding: BudgetBinding(),
    ),
    // Les autres pages (login, register, onboarding/proprietaire, etc.) seront
    // déclarées ici au fur et à mesure de leur implémentation.
  ];

  /// Indique si une route est déjà déclarée dans [pages].
  ///
  /// Permet à un écran de ne pas naviguer vers une page pas encore
  /// implémentée (et de ne pas planter au clic).
  static bool hasRoute(String name) {
    return pages.any((GetPage page) => page.name == name);
  }
}
