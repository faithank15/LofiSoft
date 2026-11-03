abstract final class AppRoutes {
  // Démarrage et authentification (lot 2)
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const joinHousing = '/join-housing';

  // Onboarding (lots 3 et 4)
  static const onboarding = '/onboarding';
  static const onboardingVille = '/onboarding/ville';
  static const onboardingType = '/onboarding/type';
  static const onboardingBudget = '/onboarding/budget';
  static const onboardingProprietaire = '/onboarding/proprietaire';

  static const dev = '/dev';

  // Accueil de chaque profil
  static const listings = '/listings';
  static const listingDetails = '/listings/details/:id';
  static const favorites = '/listings/favorites';

  static const rentTracking = '/rent-tracking';
  static const paymentHistory = '/rent-tracking/history';
  static const payment = '/payment';
  static const paymentReceipt = '/payment/receipt';

  // Espace Propriétaire (lots 7 et 8)
  static const ownerDashboard = '/owner/dashboard';
  static const ownerProperties = '/owner/properties';
  static const ownerRents = '/owner/rents';
  static const ownerPropertyDetail = '/owner/properties/detail/:id';
  static const ownerHousingCreate = '/owner/properties/new';
  static const ownerPropertyCreate = '/owner/properties/create';
  static const ownerAnnouncementCreate = '/owner/announcements/create';

  static const profile = '/profile';

  // Administration (lot 9)
  static const admin = '/admin';
  static const adminReports = '/admin/reports';
  static const adminVerifications = '/admin/verifications';
  static const adminUsers = '/admin/users';
}
