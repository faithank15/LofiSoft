import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/molecules/housing_scene.dart';
import 'welcome_controller.dart';

/// Écran E1 · Bienvenue : profil (onboarding locataire / propriétaire).
///
/// Reprend la maquette E1 : logo, titre « Bienvenue. Vous êtes… », deux
/// grandes cartes de profil (locataire / propriétaire) et le lien
/// « J'ai déjà un compte ».
class WelcomePage extends GetView<WelcomeController> {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const _TopBlock(),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Les cartes remplissent la place disponible, mais ne
                  // descendent jamais sous une hauteur lisible : sur un petit
                  // écran la page défile au lieu de déborder.
                  final double cardHeight =
                      ((constraints.maxHeight - AppSpacing.lg) / 2)
                          .clamp(176.0, 400.0);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.lg,
                      AppSpacing.screen,
                      0,
                    ),
                    child: Column(
                      children: [
                        _ProfileCard(
                          height: cardHeight,
                          background: AppColors.greenDeep,
                          subtitleColor: AppColors.mint,
                          title: 'Locataire',
                          subtitle:
                              'Je cherche un logement ou je paie mon loyer.',
                          scene: HousingSceneKind.maison,
                          onTap: controller.choisirLocataire,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ProfileCard(
                          height: cardHeight,
                          background: AppColors.clayDeep,
                          subtitleColor: AppColors.claySoft,
                          title: 'Propriétaire',
                          subtitle:
                              'Je loue mes logements et je suis les loyers.',
                          scene: HousingSceneKind.appartement,
                          onTap: controller.choisirProprietaire,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Lien secondaire : largeur intrinsèque, centré (comme la maquette).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Center(
                child: TextButton(
                  onPressed: controller.dejaUnCompte,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    minimumSize: const Size(0, AppSizes.buttonSmall),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    "J'ai déjà un compte",
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo LofiSoft + titre « Bienvenue. Vous êtes… ».
class _TopBlock extends StatelessWidget {
  const _TopBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _LofiLogo(size: 40),
              SizedBox(width: 10),
              _Wordmark(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Bienvenue. Vous êtes…',
            style: AppTextStyles.display.copyWith(
              fontSize: 36,
              height: 1.1,
              letterSpacing: -0.9,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo LofiSoft (carré vert, toit blanc, « L » ambre).
class _LofiLogo extends StatelessWidget {
  final double size;

  const _LofiLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LofiLogoPainter()),
    );
  }
}

class _LofiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 64;

    final Paint bg = Paint()..color = AppColors.green;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(16 * s),
      ),
      bg,
    );

    final Paint roof = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path roofPath = Path()
      ..moveTo(14 * s, 31 * s)
      ..lineTo(32 * s, 15 * s)
      ..lineTo(50 * s, 31 * s);
    canvas.drawPath(roofPath, roof);

    final Paint letter = Paint()
      ..color = AppColors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path letterPath = Path()
      ..moveTo(25 * s, 34 * s)
      ..lineTo(25 * s, 49 * s)
      ..lineTo(41 * s, 49 * s);
    canvas.drawPath(letterPath, letter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Nom « LofiSoft » (22 / 800).
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'Lofi',
        style: AppTextStyles.display.copyWith(
          fontSize: 22,
          height: 1.2,
          letterSpacing: -0.66,
          color: AppColors.ink,
        ),
        children: [
          TextSpan(
            text: 'Soft',
            style: AppTextStyles.display.copyWith(
              fontSize: 22,
              height: 1.2,
              letterSpacing: -0.66,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de choix de profil (Locataire / Propriétaire).
class _ProfileCard extends StatelessWidget {
  final double height;
  final Color background;
  final Color subtitleColor;
  final String title;
  final String subtitle;
  final HousingSceneKind scene;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.height,
    required this.background,
    required this.subtitleColor,
    required this.title,
    required this.subtitle,
    required this.scene,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: 0.55),
            blurRadius: 26,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.surface.withValues(alpha: 0.14),
          highlightColor: AppColors.surface.withValues(alpha: 0.07),
          child: Stack(
            children: [
              // Illustration en bas à droite
              Positioned(
                right: -6,
                bottom: 0,
                width: 150,
                height: 120,
                child: HousingScene(kind: scene),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.display.copyWith(
                        fontSize: 30,
                        height: 1.1,
                        letterSpacing: -0.6,
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 190),
                      child: Text(
                        subtitle,
                        style: AppTextStyles.body.copyWith(
                          height: 1.4,
                          color: subtitleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    const _ChooseChip(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille blanche « Choisir » (46 px de haut).
class _ChooseChip extends StatelessWidget {
  const _ChooseChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choisir',
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 18, color: AppColors.ink),
        ],
      ),
    );
  }
}
