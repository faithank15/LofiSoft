import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_logo.dart';
import '../atoms/app_wordmark.dart';
import '../atoms/skyline_band.dart';

/// Écran de lancement animé (environ 2,2 secondes) :
/// un soleil se lève derrière la ville, le logo apparaît et se trace (toit puis L),
/// le nom et la phrase d'accroche remontent en fondu, une barre ambre tourne en bas.
///
/// Composant purement visuel : il ne décide PAS où aller ensuite. C'est la page `splash/`
/// (avec son contrôleur) qui vérifie la session puis redirige.
///
/// ```dart
/// class SplashPage extends GetView<SplashController> {
///   const SplashPage({super.key});
///   @override
///   Widget build(BuildContext context) => const SplashView();
/// }
/// ```
class SplashView extends StatelessWidget {
  const SplashView({super.key, this.tagline = 'Le loyer, simplement.'});

  final String tagline;

  static const _duration = Duration(milliseconds: 2200);
  static const _citySlate = Color(0xFF072B24);

  /// Avancement (0 à 1) d'une étape située entre `begin` et `end` de l'animation.
  static double _step(double t, double begin, double end, [Curve curve = Curves.easeOutCubic]) {
    final v = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenDeep,
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: _duration,
        builder: (context, t, _) {
          final sun = _step(t, 0.0, 0.7, Curves.easeOutQuart);
          final halo = _step(t, 0.05, 0.9, Curves.easeOutQuart);
          final city = _step(t, 0.0, 0.6, Curves.easeOutQuart);
          final logoScale = _step(t, 0.2, 0.55, Curves.easeOutBack);
          final logoFade = _step(t, 0.2, 0.4);
          final draw = _step(t, 0.4, 0.75, Curves.easeOut);
          final word = _step(t, 0.55, 0.85, Curves.easeOutQuart);
          final tag = _step(t, 0.7, 1.0, Curves.easeOutQuart);

          return LayoutBuilder(
            builder: (context, box) {
              // Le halo et le soleil partagent EXACTEMENT le même centre.
              final centerY = box.maxHeight * 0.81 - 22;
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: centerY - 180,
                    height: 360,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Halo doré
                        Opacity(
                          opacity: halo,
                          child: Transform.scale(
                            scale: 0.4 + 0.6 * halo,
                            child: Container(
                              width: 360,
                              height: 360,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.amber.withValues(alpha: 0.28),
                                    AppColors.amber.withValues(alpha: 0),
                                  ],
                                  stops: const [0, 0.68],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Soleil qui se lève
                        Opacity(
                          opacity: sun,
                          child: Transform.translate(
                            offset: Offset(0, 120 * (1 - sun)),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: AppColors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              // La ville, par-devant le soleil
              Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, 70 * (1 - city)),
                  child: const SkylineBand(height: 210, color: _citySlate),
                ),
              ),
              // Logo, nom, phrase
              Align(
                alignment: const Alignment(0, -0.4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: logoFade,
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * logoScale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: -14,
                                offset: const Offset(0, 24),
                              ),
                            ],
                          ),
                          child: AppLogo(size: 104, onDark: true, drawProgress: draw),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Opacity(
                      opacity: word,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - word)),
                        child: const AppWordmark(size: 42, onDark: true),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Opacity(
                      opacity: tag,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - tag)),
                        child: Text(
                          tagline,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.mint.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Petite barre de chargement qui tourne en boucle
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 56),
                  child: Opacity(
                    opacity: math.min(1, tag * 2),
                    child: SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                        color: AppColors.amber,
                        backgroundColor: AppColors.surface.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
