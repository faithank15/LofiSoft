/// Noms de toutes les routes de l'application. Aucune chaîne en dur ailleurs :
/// on écrit toujours `AppRoutes.xxx`.
abstract final class AppRoutes {
  // Démarrage et authentification (lot 2)
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const joinHousing = '/join-housing';

  // Onboarding (lots 3 et 4)
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const onboardingVille = '/onboarding/ville';
  static const onboardingType = '/onboarding/type';
  static const onboardingBudget = '/onboarding/budget';
  static const onboardingProprietaire = '/onboarding/proprietaire';
  static const tenantOnboarding = '/onboarding/tenant';
  static const ownerOnboarding = '/onboarding/owner';

  static const dev = '/dev';

  // Accueil de chaque profil
  static const listings = '/listings';
  static const listingDetails = '/listings/details/:id';
  static const favorites = '/listings/favorites';

  static const rentTracking = '/rent-tracking';
  static const paymentHistory = '/rent-tracking/history';
  static const payment = '/payment';

  static const ownerDashboard = '/owner/dashboard';
  static const ownerProperties = '/owner/properties';

  static const admin = '/admin';
  static const adminReports = '/admin/reports';
}
