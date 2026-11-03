import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile/data/cache/app_storage.dart';
import 'package:mobile/data/cache/auth_storage.dart';
import 'package:mobile/data/remote/api_client.dart';
import 'package:mobile/presentation/features/admin/admin_binding.dart';
import 'package:mobile/presentation/features/admin/admin_controller.dart';
import 'package:mobile/presentation/features/auth/auth_binding.dart';
import 'package:mobile/presentation/features/auth/auth_controller.dart';
import 'package:mobile/presentation/features/listings/listing_binding.dart';
import 'package:mobile/presentation/features/listings/listing_form_binding.dart';
import 'package:mobile/presentation/features/listings/listing_form_controller.dart';
import 'package:mobile/presentation/features/listings/listings_controller.dart';
import 'package:mobile/presentation/features/owner_dashboard/owner_dashboard_binding.dart';
import 'package:mobile/presentation/features/owner_dashboard/owner_dashboard_controller.dart';
import 'package:mobile/presentation/features/owner_properties/property_binding.dart';
import 'package:mobile/presentation/features/owner_properties/property_controller.dart';
import 'package:mobile/presentation/features/payment/payment_binding.dart';
import 'package:mobile/presentation/features/payment/payment_controller.dart';
import 'package:mobile/presentation/features/profile/profile_binding.dart';
import 'package:mobile/presentation/features/profile/profile_controller.dart';
import 'package:mobile/presentation/features/rent_tracking/rent_tracking_binding.dart';
import 'package:mobile/presentation/features/rent_tracking/rent_tracking_controller.dart';
import 'package:mobile/presentation/features/rental/join_housing_binding.dart';
import 'package:mobile/presentation/features/rental/join_housing_controller.dart';

import '../support/fakes.dart';

/// Chaque écran obtient son contrôleur par son binding, exactement comme dans l'app :
/// seuls ApiClient, AuthStorage et AppStorage sont enregistrés au démarrage (di/injector.dart).
/// (Les autres tests construisent les contrôleurs à la main et ne vérifient pas ce câblage.)
void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.testMode = true;
    final auth = MemoryAuthStorage();
    Get.put<AuthStorage>(auth, permanent: true);
    Get.put<AppStorage>(MemoryAppStorage(), permanent: true);
    Get.put<ApiClient>(ApiClient(authStorage: auth), permanent: true);
  });
  tearDown(Get.reset);

  final cases = <String, (Bindings, Object Function())>{
    'AuthBinding': (AuthBinding(), () => Get.find<AuthController>()),
    'ListingBinding': (ListingBinding(), () => Get.find<ListingsController>()),
    'ListingFormBinding': (ListingFormBinding(), () => Get.find<ListingFormController>()),
    'OwnerDashboardBinding': (OwnerDashboardBinding(), () => Get.find<OwnerDashboardController>()),
    'PropertyBinding': (PropertyBinding(), () => Get.find<PropertyController>()),
    'RentTrackingBinding': (RentTrackingBinding(), () => Get.find<RentTrackingController>()),
    'JoinHousingBinding': (JoinHousingBinding(), () => Get.find<JoinHousingController>()),
    'ProfileBinding': (ProfileBinding(), () => Get.find<ProfileController>()),
    'AdminBinding': (AdminBinding(), () => Get.find<AdminController>()),
    'PaymentBinding': (PaymentBinding(), () => Get.find<PaymentController>()),
  };

  cases.forEach((name, c) {
    test('$name fournit son contrôleur', () {
      c.$1.dependencies();
      expect(c.$2, isNotNull);
    });
  });
}
