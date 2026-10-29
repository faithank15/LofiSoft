import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/screen_title.dart';
import '../../components/molecules/bottom_cta_bar.dart';
import '../../components/molecules/onboarding_top_nav.dart';
import '../../components/molecules/owner_illustration_panel.dart';
import '../../components/molecules/owner_step_list.dart';
import 'onboarding_controller.dart';

/// Écran d'onboarding propriétaire assemblant les maquettes E5, E6 et E7.
///
/// Référence de design du parcours : la barre haute et la zone d'action basse
/// sont partagées avec le parcours locataire (E2 → E4).

class OwnerOnboardingPage extends GetView<OnboardingController> {
  const OwnerOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.currentStep.value == 0;
      final backgroundColor = isDark ? AppColors.greenDeep : AppColors.paper;
      final overlayStyle = isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.greenDeep,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.paper,
            );

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                OnboardingTopNav(
                  currentStep: controller.currentStep.value,
                  totalSteps: 3,
                  onSkip: controller.skip,
                  onBack: controller.previousStep,
                  isLight: isDark,
                ),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    physics: const ClampingScrollPhysics(),
                    children: const [
                      _OwnerWelcomeView(),
                      _OwnerProcessView(),
                      _OwnerVerificationView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Étape E5 : Bienvenue et aperçu des loyers
class _OwnerWelcomeView extends GetView<OnboardingController> {
  const _OwnerWelcomeView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.md),
                OwnerIllustrationPanel(
                  type: IllustrationType.ownerWelcome,
                  height: 204,
                ),
                SizedBox(height: AppSpacing.xl),
                ScreenTitle(
                  title: 'Tous vos loyers, d’un coup d’œil.',
                  subtitle:
                      'Voyez qui a payé et qui est en retard. L’argent arrive directement sur votre Mobile Money.',
                  isLight: true,
                ),
                SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
        BottomCtaBar(
          primaryLabel: 'Continuer',
          onPrimary: controller.nextStep,
          primaryVariant: AppButtonVariant.surface,
        ),
      ],
    );
  }
}

/// Étape E6 : Les 3 étapes de configuration
class _OwnerProcessView extends GetView<OnboardingController> {
  const _OwnerProcessView();

  static const List<OwnerStepItem> _items = [
    OwnerStepItem(
      number: 1,
      title: 'Ajoutez vos logements',
      description:
          'Nom, adresse et loyer. Publiez une annonce si le logement est libre.',
    ),
    OwnerStepItem(
      number: 2,
      title: 'Donnez le code à vos locataires',
      description:
          'Chaque logement a son code. Le locataire l’entre dans l’application.',
    ),
    OwnerStepItem(
      number: 3,
      title: 'Suivez les paiements',
      description:
          'Vous voyez qui a payé, et vous êtes prévenu à chaque paiement.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.sm),
                ScreenTitle(title: 'Démarrer prend 3 minutes.'),
                SizedBox(height: AppSpacing.xxl),
                OwnerStepList(items: _items),
                SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
        BottomCtaBar(
          primaryLabel: 'Continuer',
          onPrimary: controller.nextStep,
        ),
      ],
    );
  }
}

/// Étape E7 : Demande du badge Vérifié
class _OwnerVerificationView extends GetView<OnboardingController> {
  const _OwnerVerificationView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.sm),
                OwnerIllustrationPanel(
                  type: IllustrationType.ownerVerification,
                  height: 250,
                ),
                SizedBox(height: AppSpacing.xl),
                ScreenTitle(
                  title: 'Obtenez le badge Vérifié.',
                  subtitle:
                      'Les locataires font plus confiance aux propriétaires vérifiés. Il suffit d’envoyer une photo de votre pièce d’identité. Nous la vérifions sous 48 h.',
                ),
                SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
        // `Obx` local : les vues du PageView sont construites hors du `Obx`
        // de la page, l'indicateur de chargement doit donc s'abonner
        // lui-même à l'état asynchrone.
        Obx(
          () => BottomCtaBar(
            primaryLabel: 'Envoyer ma pièce d’identité',
            onPrimary: () => controller.pickIdentityDocument(),
            isLoading: controller.isLoading.value,
            secondaryLabel: 'Plus tard',
            onSecondary: controller.finishOnboarding,
          ),
        ),
      ],
    );
  }
}
