import 'package:get/get.dart';

import '../features/auth/auth_binding.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/splash/splash_binding.dart';
import '../features/splash/splash_page.dart';
import '../shared/placeholder_page.dart';
import '../shared/dev_menu_page.dart';
import '../../core/constants/app_config.dart';

import 'app_routes.dart';

/// Table qui relie chaque route à sa page et à son binding.
/// Chaque personne ajoute ses routes dans la section de son lot.
abstract final class AppPages {

  static const initial = AppConfig.useFakeApi ? AppRoutes.dev : AppRoutes.splash;

  static final pages = <GetPage<dynamic>>[
    // ---- Lot 2 : démarrage et authentification ----
    GetPage(name: AppRoutes.dev, page: () => const DevMenuPage()),
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),

    GetPage(name: AppRoutes.onboarding,     page: () => const PlaceholderPage(title: 'Onboarding')),
    GetPage(name: AppRoutes.listings,       page: () => const PlaceholderPage(title: 'Annonces')),
    GetPage(name: AppRoutes.rentTracking,   page: () => const PlaceholderPage(title: 'Suivi du loyer')),
    GetPage(name: AppRoutes.ownerDashboard, page: () => const PlaceholderPage(title: 'Tableau de bord propriétaire')),
    GetPage(name: AppRoutes.admin,          page: () => const PlaceholderPage(title: 'Administration')),
    GetPage(name: AppRoutes.forgotPassword, page: () => const PlaceholderPage(title: 'Mot de passe oublié')),

    // ---- Lots 3 et 4 : onboarding ----
    // GetPage(name: AppRoutes.onboarding, page: () => const OnboardingPage(), binding: OnboardingBinding()),

    // ---- Lot 1 : annonces ----
    // GetPage(name: AppRoutes.listings, page: () => const ListingsFeedPage(), binding: ListingBinding()),

    // ---- Lot 5 : suivi du loyer (locataire) ----
    // GetPage(name: AppRoutes.rentTracking, ...),

    // ---- Lot 7 : tableau de bord propriétaire ----
    // GetPage(name: AppRoutes.ownerDashboard, ...),

    // ---- Lot 10 : administration ----
    // GetPage(name: AppRoutes.admin, ...),
  ];
}