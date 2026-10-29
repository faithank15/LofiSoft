import 'package:get/get.dart';

import 'onboarding_completion.dart';
import 'tenant_preferences.dart';

/// Contrôleur de l'écran E4 (choix du budget — locataire).
class BudgetController extends GetxController {
  /// Valeur enregistrée quand l'utilisateur choisit de voir tous les logements.
  static const budgetSansFiltre = 'all';

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

  /// Action principale « Voir mes logements » : termine le parcours locataire
  /// en conservant la tranche de budget choisie.
  Future<void> continuer() async {
    await TenantPreferences.enregistrer(budget: selectedBudget.value);
    await OnboardingCompletion.terminerLocataire();
  }

  /// Action secondaire « Voir tous les logements » : termine le parcours
  /// locataire sans filtre de budget.
  Future<void> voirTousLesLogements() async {
    await TenantPreferences.enregistrer(budget: budgetSansFiltre);
    await OnboardingCompletion.terminerLocataire();
  }

  /// Action « Passer » : quitte le parcours locataire sans aller au bout.
  Future<void> passer() => OnboardingCompletion.terminerLocataire();
}
