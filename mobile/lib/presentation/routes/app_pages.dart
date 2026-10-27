import '../features/listings/listing_details_page.dart';
import '../features/listings/favorites_page.dart';
import '../features/listings/listing_binding.dart';
import '../features/listings/listings_feed_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
import '../shared/dev_menu_page.dart';
import '../../core/constants/app_config.dart';

import 'app_routes.dart';

/// Table qui relie chaque route à sa page et à son binding.
/// Chaque personne ajoute ses routes dans la section de son lot.
abstract final class AppPages {

  static const initial = AppConfig.useFakeApi ? AppRoutes.dev : AppRoutes.splash;

  /// Indique si une route est déjà déclarée dans [pages] (évite de naviguer
  /// vers une page pas encore implémentée).
  static bool hasRoute(String name) => pages.any((page) => page.name == name);

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

    GetPage(name: AppRoutes.rentTracking,   page: () => const PlaceholderPage(title: 'Suivi du loyer')),
    GetPage(name: AppRoutes.admin,          page: () => const PlaceholderPage(title: 'Administration')),
    GetPage(name: AppRoutes.forgotPassword, page: () => const PlaceholderPage(title: 'Mot de passe oublié')),

    // ---- Lots 3 et 4 : onboarding ----
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
    GetPage(
      name: AppRoutes.ownerOnboarding,
      page: () => const OwnerOnboardingPage(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),
    // GetPage(name: AppRoutes.onboarding, page: () => const OnboardingPage(), binding: OnboardingBinding()),

    // ---- Lot 1 : annonces ----
    GetPage(name: AppRoutes.listings, page: () => const ListingsFeedPage(), binding: ListingBinding()),
    GetPage(name: AppRoutes.favorites, page: () => const FavoritesPage(), binding: ListingBinding()),
    GetPage(name: AppRoutes.listingDetails, page: () => const ListingDetailsPage(), binding: ListingBinding()),


    // ---- Lot 5 : suivi du loyer (locataire) ----
    // GetPage(name: AppRoutes.rentTracking, ...),

    // ---- Lot 7 : tableau de bord propriétaire ----
    // Page d'atterrissage temporaire, à remplacer par le vrai tableau de bord.
    GetPage(
      name: AppRoutes.ownerDashboard,
      page: () => const _OwnerDashboardPlaceholderPage(),
      transition: Transition.fadeIn,
    ),

    // ---- Lot 10 : administration ----
    // GetPage(name: AppRoutes.admin, ...),
  ];
}

/// Écran d'atterrissage temporaire pour valider la sortie de l'onboarding
/// avant la livraison complète du Lot 7.
class _OwnerDashboardPlaceholderPage extends StatelessWidget {
  const _OwnerDashboardPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Tableau de bord propriétaire'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppColors.statusOk,
              ),
              const SizedBox(height: 16),
              Text(
                'Onboarding terminé avec succès',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Redirection opérationnelle vers AppRoutes.ownerDashboard',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
