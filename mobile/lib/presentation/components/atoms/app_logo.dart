import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

/// Logo « Maison L » : un toit blanc et un L ambre (qui forme aussi une clé/une porte).
/// Dessiné en code : pas besoin de fichier image ni de paquet SVG.
///
/// ```dart
/// AppLogo(size: 36)                 // sur fond clair : carré vert
/// AppLogo(size: 104, onDark: true)  // sur fond vert profond : carré crème, toit vert
/// ```
///
/// Net à toutes les tailles : au repos, le logo est un vrai SVG (rendu vectoriel par flutter_svg).
/// Le dessin par code (CustomPaint) n'est utilisé QUE pendant l'animation de tracé du lancement.
///
/// `drawProgress` (0 à 1) sert à l'animation de lancement : le toit se trace d'abord
/// (0 à 0,5), puis le L (0,5 à 1). Laisser à 1 partout ailleurs.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 36,
    this.onDark = false,
    this.drawProgress = 1,
  });

  final double size;

  /// `true` quand le logo est posé sur un fond sombre (écran de lancement, bandeau).
  final bool onDark;

  /// Avancement du tracé du toit et du L, de 0 (rien) à 1 (complet).
  final double drawProgress;

  static const _lightSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">'
      '<rect width="64" height="64" rx="16" fill="#0F5C4D"/>'
      '<path d="M14 31 L32 15 L50 31" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
      '<path d="M25 34 V49 H41" fill="none" stroke="#F2B134" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  static const _darkSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">'
      '<rect width="64" height="64" rx="16" fill="#F7F3EA"/>'
      '<path d="M14 31 L32 15 L50 31" fill="none" stroke="#0F5C4D" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
      '<path d="M25 34 V49 H41" fill="none" stroke="#F2B134" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    final Widget logo = drawProgress >= 1
        ? SvgPicture.string(onDark ? _darkSvg : _lightSvg, width: size, height: size)
        : CustomPaint(painter: _LogoPainter(onDark: onDark, progress: drawProgress));
    return Semantics(
      label: 'Logo LofiSoft',
      image: true,
      child: SizedBox(width: size, height: size, child: logo),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.onDark, required this.progress});

  final bool onDark;
  final double progress;

  void _strokePartial(Canvas canvas, Path path, Paint paint, double t) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Le dessin est conçu sur une grille 64 x 64, puis mis à l'échelle.
    final s = size.width / 64;

    final background = Paint()..color = onDark ? AppColors.paper : AppColors.green;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(16 * s)),
      background,
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roof = Path()
      ..moveTo(14 * s, 31 * s)
      ..lineTo(32 * s, 15 * s)
      ..lineTo(50 * s, 31 * s);
    _strokePartial(
      canvas,
      roof,
      stroke..color = onDark ? AppColors.green : AppColors.surface,
      (progress / 0.5).clamp(0.0, 1.0),
    );

    final l = Path()
      ..moveTo(25 * s, 34 * s)
      ..lineTo(25 * s, 49 * s)
      ..lineTo(41 * s, 49 * s);
    _strokePartial(
      canvas,
      l,
      stroke..color = AppColors.amber,
      ((progress - 0.5) / 0.5).clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.onDark != onDark || old.progress != progress;
}
