import '../features/rent_tracking/payment_history_page.dart';
import '../features/rent_tracking/rent_tracking_binding.dart';
import '../features/rent_tracking/rent_tracking_page.dart';
import '../features/listings/listing_details_page.dart';
import '../features/rental/join_housing_binding.dart';
import '../features/rental/join_housing_page.dart';
import '../features/listings/favorites_page.dart';
import '../features/listings/listing_binding.dart';
import '../features/listings/listings_feed_page.dart';
import 'package:get/get.dart';

import '../features/auth/auth_binding.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/onboarding/budget_binding.dart';
import '../features/onboarding/budget_page.dart';
import '../features/onboarding/onboarding_binding.dart';
import '../features/onboarding/owner_onboarding_page.dart';
import '../features/onboarding/type_binding.dart';
import '../features/onboarding/type_page.dart';
import '../features/onboarding/ville_binding.dart';
import '../features/onboarding/ville_page.dart';
import '../features/onboarding/welcome_binding.dart';
import '../features/onboarding/welcome_page.dart';
import '../features/splash/splash_binding.dart';
import '../features/splash/splash_page.dart';
import '../shared/placeholder_page.dart';
import '../features/dev/dev_menu_page.dart';
import '../features/owner_dashboard/owner_dashboard_page.dart';
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

    GetPage(
      name: AppRoutes.joinHousing,
      page: () => const JoinHousingPage(),
      binding: JoinHousingBinding(),
    ),

    // Point d'entrée de l'onboarding (utilisé par le splash à la première ouverture).
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const WelcomePage(),
      binding: WelcomeBinding(),
    ),
    GetPage(name: AppRoutes.rentTracking, page: () => const RentTrackingPage(), binding: RentTrackingBinding()),
    GetPage(name: AppRoutes.paymentHistory, page: () => const PaymentHistoryPage(), binding: RentTrackingBinding()),
    GetPage(name: AppRoutes.admin,          page: () => const PlaceholderPage(title: 'Administration')),
    GetPage(name: AppRoutes.forgotPassword, page: () => const PlaceholderPage(title: 'Mot de passe oublié')),

    // ---- Lots 3 et 4 : onboarding ----
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
    // Parcours propriétaire : E5 (bienvenue) → E6 (étapes) → E7 (badge vérifié).
    GetPage(
      name: AppRoutes.onboardingProprietaire,
      page: () => const OwnerOnboardingPage(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),
    // GetPage(name: AppRoutes.onboarding, page: () => const OnboardingPage(), binding: OnboardingBinding()),

    // ---- Lot 1 : annonces ----
    GetPage(name: AppRoutes.listings, page: () => const ListingsFeedPage(), binding: ListingBinding()),
    GetPage(name: AppRoutes.favorites, page: () => const FavoritesPage(), binding: ListingBinding()),
    GetPage(name: AppRoutes.listingDetails, page: () => const ListingDetailsPage(), binding: ListingDetailsBinding()),


    // ---- Lot 5 : suivi du loyer (locataire) ----
    // GetPage(name: AppRoutes.rentTracking, ...),

    // ---- Lot 7 : tableau de bord propriétaire ----
    // Page d'atterrissage temporaire, à remplacer par le vrai tableau de bord.
    GetPage(
      name: AppRoutes.ownerDashboard,
      page: () => const OwnerDashboardPage(),
      transition: Transition.fadeIn,
    ),

    // ---- Lot 10 : administration ----
    // GetPage(name: AppRoutes.admin, ...),
  ];
}
