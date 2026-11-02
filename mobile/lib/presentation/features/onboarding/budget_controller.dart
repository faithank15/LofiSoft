import 'package:get/get.dart';
import '../../../data/cache/app_storage.dart';
import 'onboarding_completion.dart';

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

  /// Enregistre le budget, termine l'onboarding et ouvre le fil d'annonces filtré.
  Future<void> continuer() async {
    final storage = Get.find<AppStorage>();
    await storage.savePreferences(storage.preferences.copyWith(budgetLabel: selectedBudget.value));
    await OnboardingCompletion.terminerLocataire();
  }

  /// Action secondaire : voir tous les logements, sans critères.
  Future<void> voirTousLesLogements() async {
    final storage = Get.find<AppStorage>();
    await storage.clearPreferences();
    await OnboardingCompletion.terminerLocataire();
  }

  /// Action « Passer » : quitte le parcours locataire sans aller au bout.
  Future<void> passer() => OnboardingCompletion.terminerLocataire();
}
