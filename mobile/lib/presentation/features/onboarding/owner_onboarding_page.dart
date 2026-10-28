import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/screen_title.dart';
import '../../components/molecules/owner_illustration_panel.dart';
import '../../components/molecules/owner_step_list.dart';
import 'onboarding_controller.dart';

/// Écran d'onboarding propriétaire assemblant les maquettes E5, E6 et E7.

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
                _buildTopNavigation(isDark: isDark),
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

  Widget _buildTopNavigation({required bool isDark}) {
    final skipColor = isDark ? AppColors.mint : AppColors.muted;
    final activeSegment = isDark ? AppColors.surface : AppColors.green;
    final inactiveSegment = isDark
        ? AppColors.surface.withValues(alpha: 0.25)
        : AppColors.line;

    return Container(
      height: AppSizes.appBar,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          AppBackButton(isLight: isDark, onPressed: controller.previousStep),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: List.generate(3, (index) {
                  final isReached = controller.currentStep.value >= index;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(
                        right: index < 2 ? AppSpacing.xs : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isReached ? activeSegment : inactiveSegment,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          TextButton(
            onPressed: controller.skip,
            child: Text(
              'Passer',
              style: AppTextStyles.label.copyWith(
                color: skipColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: AppButton(
            label: 'Continuer',
            variant: AppButtonVariant.surface,
            onPressed: controller.nextStep,
          ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: AppButton(
            label: 'Continuer',
            variant: AppButtonVariant.primary,
            onPressed: controller.nextStep,
          ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: 'Envoyer ma pièce d’identité',
                variant: AppButtonVariant.primary,
                isLoading: controller.isLoading.value,
                onPressed: () => controller.pickIdentityDocument(),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: 'Plus tard',
                variant: AppButtonVariant.text,
                height: AppSizes.tap,
                onPressed: controller.finishOnboarding,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
