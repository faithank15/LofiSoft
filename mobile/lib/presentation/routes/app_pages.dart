import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../features/onboarding/onboarding_binding.dart';
import '../features/onboarding/owner_onboarding_page.dart';
import 'app_routes.dart';

/// Table officielle d'enregistrement des pages, bindings et transitions GetX.
abstract final class AppPages {
  static const initial = AppRoutes.ownerOnboarding;

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRoutes.ownerOnboarding,
      page: () => const OwnerOnboardingPage(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.ownerDashboard,
      page: () => const _OwnerDashboardPlaceholderPage(),
      transition: Transition.fadeIn,
    ),
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
