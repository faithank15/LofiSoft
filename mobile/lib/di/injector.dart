import 'package:get/get.dart';

import '../data/cache/app_storage.dart';
import '../data/cache/auth_storage.dart';
import '../data/remote/api_client.dart';

/// Point de composition : enregistre les singletons d'infrastructure.
///
/// Ce module vit à la racine de `lib/`, volontairement hors des couches
/// `core/` / `data/` / `domain/` / `presentation/` : il est le seul endroit
/// autorisé à relier entre elles les briques d'infrastructure, ce qui évite
/// toute inversion de dépendance (notamment `core/` → `data/`).
Future<void> initializeDependencies() async {
  final authStorage = Get.put(AuthStorage(), permanent: true);
  Get.put(AppStorage(), permanent: true);
  Get.put(ApiClient(authStorage: authStorage), permanent: true);
}
