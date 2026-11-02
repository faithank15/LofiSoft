import 'package:get/get.dart';

import '../../core/constants/app_config.dart';
import '../features/admin/admin_binding.dart';
import '../features/admin/admin_reports_page.dart';
import '../features/admin/admin_verifications_page.dart';
import '../features/auth/auth_binding.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/dev/dev_menu_page.dart';
import '../features/listings/favorites_page.dart';
import '../features/listings/listing_binding.dart';
import '../features/listings/listing_details_page.dart';
import '../features/listings/listing_form_binding.dart';
import '../features/listings/listing_form_page.dart';
import '../features/listings/listings_feed_page.dart';
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
import '../features/owner_dashboard/owner_dashboard_binding.dart';
import '../features/owner_dashboard/owner_dashboard_page.dart';
import '../features/owner_dashboard/owner_rents_page.dart';
import '../features/owner_properties/property_binding.dart';
import '../features/owner_properties/property_detail_page.dart';
import '../features/owner_properties/property_form_page.dart';
import '../features/owner_properties/property_list_page.dart';
import '../features/profile/profile_binding.dart';
import '../features/profile/profile_page.dart';
import '../features/rent_tracking/payment_history_page.dart';
import '../features/rent_tracking/rent_tracking_binding.dart';
import '../features/rent_tracking/rent_tracking_page.dart';
import '../features/rental/join_housing_binding.dart';
import '../features/rental/join_housing_page.dart';
import '../features/splash/splash_binding.dart';
import '../features/splash/splash_page.dart';
import '../shared/placeholder_page.dart';
import 'app_routes.dart';

/// Table reliant chaque route à sa page et à son binding d'injection.
abstract final class AppPages {
  static const initial = AppConfig.useFakeApi
      ? AppRoutes.dev
      : AppRoutes.splash;

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

    // Point d'entrée de l'onboarding
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const WelcomePage(),
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: AppRoutes.rentTracking,
      page: () => const RentTrackingPage(),
      binding: RentTrackingBinding(),
    ),
    GetPage(
      name: AppRoutes.paymentHistory,
      page: () => const PaymentHistoryPage(),
      binding: RentTrackingBinding(),
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminReportsPage(),
      binding: AdminBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const PlaceholderPage(title: 'Mot de passe oublié'),
    ),

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
    GetPage(
      name: AppRoutes.onboardingProprietaire,
      page: () => const OwnerOnboardingPage(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),

    // ---- Lot 1 : annonces ----
    GetPage(
      name: AppRoutes.listings,
      page: () => const ListingsFeedPage(),
      binding: ListingBinding(),
    ),
    GetPage(
      name: AppRoutes.favorites,
      page: () => const FavoritesPage(),
      binding: ListingBinding(),
    ),
    GetPage(
      name: AppRoutes.listingDetails,
      page: () => const ListingDetailsPage(),
      binding: ListingDetailsBinding(),
    ),

    // ---- Lot 7 : tableau de bord propriétaire ----
    GetPage(
      name: AppRoutes.ownerDashboard,
      page: () => const OwnerDashboardPage(),
      binding: OwnerDashboardBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.ownerRents,
      page: () => const OwnerRentsPage(),
      binding: OwnerDashboardBinding(),
    ),

    // ---- Profil (tous les rôles) ----
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),

    // ---- Lot 9 : administration ----
    GetPage(
      name: AppRoutes.adminReports,
      page: () => const AdminReportsPage(),
      binding: AdminBinding(),
    ),
    GetPage(
      name: AppRoutes.adminVerifications,
      page: () => const AdminVerificationsPage(),
      binding: AdminBinding(),
    ),

    // ---- C3 et C4 : nouvelle annonce ----
    GetPage(
      name: AppRoutes.ownerAnnouncementCreate,
      page: () => const ListingFormPage(),
      binding: ListingFormBinding(),
    ),

    // ---- Lot 8 : logements propriétaire ----
    GetPage(
      name: AppRoutes.ownerProperties,
      page: () => const PropertyListPage(),
      binding: PropertyBinding(),
    ),
    GetPage(
      name: AppRoutes.ownerPropertyDetail,
      page: () => const PropertyDetailPage(),
      binding: PropertyBinding(),
    ),
    GetPage(
      name: AppRoutes.ownerPropertyCreate,
      page: () => const PropertyFormPage(),
      binding: PropertyBinding(),
    ),
  ];
}