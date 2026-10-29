import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile/data/cache/app_storage.dart';
import 'package:mobile/data/cache/auth_storage.dart';
import 'package:mobile/data/remote/api_client.dart';
import 'package:mobile/di/injector.dart';

void main() {
  // `GetStorage.init()` passe par path_provider, absent des tests unitaires :
  // on simule le canal pour obtenir un répertoire temporaire.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('lofisoft_test');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
            case 'getTemporaryDirectory':
            case 'getLibraryDirectory':
              return tempDir.path;
          }
          return null;
        });
    await GetStorage.init();
  });

  tearDownAll(() async {
    await GetStorage().erase();
    // Sous Windows, GetStorage peut encore détenir un descripteur sur le
    // fichier : la suppression du dossier temporaire est best-effort.
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // Ignoré : le dossier est dans le répertoire temporaire du système.
    }
  });

  tearDown(Get.reset);

  test('initializeDependencies() enregistre les singletons d\'infrastructure', () async {
    await initializeDependencies();

    expect(Get.isRegistered<AuthStorage>(), isTrue);
    expect(Get.isRegistered<AppStorage>(), isTrue);
    expect(Get.isRegistered<ApiClient>(), isTrue);
  });

  test('les singletons enregistrés sont bien des instances attendues', () async {
    await initializeDependencies();

    expect(Get.find<AuthStorage>(), isA<AuthStorage>());
    expect(Get.find<AppStorage>(), isA<AppStorage>());
    expect(Get.find<ApiClient>(), isA<ApiClient>());
  });
}
