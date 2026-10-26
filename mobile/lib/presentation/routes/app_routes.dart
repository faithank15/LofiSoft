/// Noms de toutes les routes de l'application. Aucune chaîne en dur ailleurs :
/// on écrit toujours `AppRoutes.xxx`.
abstract final class AppRoutes {
  // Démarrage et authentification (lot 2)
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Onboarding (lots 3 et 4)
  static const onboarding = '/onboarding';

  static const dev = '/dev';

  // Accueil de chaque profil
  static const listings = '/listings';
  static const rentTracking = '/rent-tracking';
  static const ownerDashboard = '/owner-dashboard';
  static const admin = '/admin';
}