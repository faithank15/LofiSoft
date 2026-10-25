/// Déclaration centralisée et scellée de tous les noms de routes LofiSoft.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const joinHousing = '/join-housing';

  static const tenantOnboarding = '/onboarding/tenant';
  static const ownerOnboarding = '/onboarding/owner';

  static const listings = '/listings';
  static const listingDetails = '/listings/details/:id';

  static const rentTracking = '/rent-tracking';
  static const payment = '/payment';

  static const ownerDashboard = '/owner/dashboard';
  static const ownerProperties = '/owner/properties';

  static const adminReports = '/admin/reports';
}
