import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'presentation/routes/app_pages.dart';
import 'presentation/routes/app_routes.dart';

/// Point d'entrée principal de l'application LofiSoft.
///
/// Configure GetMaterialApp avec le thème Material 3, la table de routes et
/// la route initiale.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LofiSoft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.welcome,
      getPages: AppPages.pages,
    );
  }
}
