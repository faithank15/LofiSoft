import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';
import 'di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Singletons d'infrastructure (vivent pendant toute la durée de l'app).
  await initializeDependencies();

  runApp(const App());
}
