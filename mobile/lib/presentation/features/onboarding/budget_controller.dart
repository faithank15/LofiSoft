import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../routes/app_pages.dart';
import '../../routes/app_routes.dart';

/// Contrôleur de l'écran E4 (choix du budget — locataire).
class BudgetController extends GetxController {
  /// Liste des tranches de budget proposées.
  static const _budgets = [
    'Moins de 100 000 FCFA',
    '100 000 à 300 000 FCFA',
    '300 000 à 500 000 FCFA',
    'Plus de 500 000 FCFA',
  ];

  /// Sous-titres associés à chaque tranche.
  static const Map<String, String> _subtitles = {
    'Moins de 100 000 FCFA': 'Chambres et studios',
    '100 000 à 300 000 FCFA': 'Studios et appartements',
    '300 000 à 500 000 FCFA': 'Grands appartements et maisons',
    'Plus de 500 000 FCFA': 'Villas et logements de standing',
  };

  /// Budget actuellement sélectionné (défaut : la tranche sélectionnée dans la maquette).
  final selectedBudget = '100 000 à 300 000 FCFA'.obs;

  /// Retourne la liste des tranches.
  List<String> get budgets => _budgets;

  /// Retourne le sous-titre de la tranche donnée.
  String subtitleFor(String budget) => _subtitles[budget] ?? '';

  /// Indique si une tranche est sélectionnée.
  bool isSelected(String budget) => selectedBudget.value == budget;

  /// Sélectionne une tranche de budget.
  void selectBudget(String budget) {
    selectedBudget.value = budget;
  }

  /// Navigue vers l'écran suivant (propriétaire — E5).
  ///
  /// Tant que l'écran E5 n'est pas implémenté, on ne navigue pas : on
  /// prévient l'utilisateur au lieu de planter sur une route inconnue.
  void continuer() {
    if (!AppPages.hasRoute(AppRoutes.onboardingProprietaire)) {
      Get.snackbar(
        'Bientôt disponible',
        'La suite du parcours propriétaire arrive.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.green.withValues(alpha: 0.9),
        colorText: AppColors.surface,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    Get.toNamed(AppRoutes.onboardingProprietaire);
  }

  /// Action secondaire : voir tous les logements.
  void voirTousLesLogements() {
    Get.snackbar(
      'Information',
      'Tous les logements disponibles.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.green.withValues(alpha: 0.9),
      colorText: AppColors.surface,
      duration: const Duration(seconds: 2),
    );
  }
}
