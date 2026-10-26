import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/skeletons/splash_view.dart';
import 'splash_controller.dart';

/// E0 · Lancement. Aucun champ de texte : GetView suffit.
class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const SplashView();
}
