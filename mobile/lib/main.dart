import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'data/cache/app_storage.dart';
import 'data/cache/auth_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Singletons d'infrastructure (vivent pendant toute la durée de l'app)
  final authStorage = Get.put(AuthStorage(), permanent: true);
  Get.put(AppStorage(), permanent: true);
  Get.put(ApiClient(authStorage: authStorage), permanent: true);

  runApp(const App());
}
