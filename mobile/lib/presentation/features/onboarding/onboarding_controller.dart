import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';

/// Contrôleur GetX gérant l'état et les transitions de l'onboarding.
///
/// Ne contient aucune logique d'UI ni contrôleurs de texte, conformément
/// aux règles architecturales du projet.
class OnboardingController extends GetxController {
  OnboardingController({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  late final PageController pageController;

  /// Index réactif de l'étape courante (0: E5, 1: E6, 2: E7).
  final RxInt currentStep = 0.obs;

  /// Document d'identité capturé lors de l'étape E7.
  final Rxn<XFile> pickedIdentityDocument = Rxn<XFile>();

  /// Indicateur d'action asynchrone en cours.
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: currentStep.value);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    currentStep.value = index;
  }

  void nextStep() {
    if (currentStep.value < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      finishOnboarding();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  void skip() {
    finishOnboarding();
  }

  Future<void> pickIdentityDocument({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      isLoading.value = true;
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (file != null) {
        pickedIdentityDocument.value = file;
        finishOnboarding();
      }
    } catch (_) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger la pièce d\'identité.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void finishOnboarding() {
    Get.offAllNamed(AppRoutes.ownerDashboard);
  }
}
