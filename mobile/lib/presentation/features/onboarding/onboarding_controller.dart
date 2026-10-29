import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/cache/app_storage.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../data/repo/identity_repository.dart';
import '../../routes/app_routes.dart';

/// Contrôleur GetX gérant l'état et les transitions de l'onboarding.
///
/// Ne contient aucune logique d'UI ni contrôleurs de texte, conformément
/// aux règles architecturales du projet.
class OnboardingController extends GetxController {
  OnboardingController({required IdentityRepository repository, ImagePicker? imagePicker})
    : _repository = repository,
      _imagePicker = imagePicker ?? ImagePicker();

  final IdentityRepository _repository;
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

  Future<void> skip() async {
    await finishOnboarding();
  }

  /// E7 : l'API demande la pièce d'identité ET un selfie. On prend la pièce
  /// (galerie ou appareil photo), puis le selfie à l'appareil photo, puis on envoie les deux.
  Future<void> pickIdentityDocument({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (isLoading.value) return;
    if (!Get.find<AuthStorage>().hasSession) {
      Get.snackbar(
        'Compte requis',
        'Créez votre compte propriétaire pour envoyer votre pièce d’identité.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.toNamed(AppRoutes.register);
      return;
    }
    try {
      isLoading.value = true;
      final document = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (document == null) return;
      pickedIdentityDocument.value = document;

      Get.snackbar(
        'Un selfie, maintenant',
        'Prenez-vous en photo pour confirmer que la pièce est bien la vôtre.',
        snackPosition: SnackPosition.BOTTOM,
      );
      final selfie = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (selfie == null) return;

      await _repository.submit(idImagePath: document.path, selfiePath: selfie.path);
      Get.snackbar(
        'Envoyé',
        'Nous vérifions votre pièce sous 48 h.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await finishOnboarding();
    } on AppException catch (e) {
      Get.snackbar('Erreur', e.message, snackPosition: SnackPosition.BOTTOM);
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

  Future<void> finishOnboarding() async {
    await Get.find<AppStorage>().markOnboardingDone();
    Get.offAllNamed(AppRoutes.ownerDashboard);
  }
}
