import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Frise décorative de toits de maisons (la « ville » de LofiSoft).
/// Utilisée en bas du bandeau de connexion, sur l'écran de lancement et dans la jauge.
///
/// ```dart
/// SkylineBand(height: 70)                     // blanc 7 % (sur fond vert profond)
/// SkylineBand(height: 210, color: Color(0xFF072B24))
/// SkylineBand(height: 52, litWindows: true)   // fenêtres ambre allumées
/// ```
/// Prend toute la largeur disponible.
class SkylineBand extends StatelessWidget {
  const SkylineBand({
    super.key,
    this.height = 70,
    this.color,
    this.litWindows = false,
    this.heightFactor = 0.62,
  });

  final double height;

  /// Couleur des bâtiments. Par défaut : blanc très transparent.
  final Color? color;

  /// Ajoute de petites fenêtres ambre.
  final bool litWindows;

  /// Part de la hauteur occupée par le plus grand bâtiment (0 à 1).
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
          painter: _SkylinePainter(
            color: color ?? AppColors.surface.withValues(alpha: 0.07),
            lit: litWindows,
            factor: heightFactor,
          ),
        ),
      ),
    );
  }
}

class _SkylinePainter extends CustomPainter {
  const _SkylinePainter({required this.color, required this.lit, required this.factor});

  final Color color;
  final bool lit;
  final double factor;

  static const _widths = [22.0, 18, 26, 16, 24, 20, 28, 18, 22, 16, 26, 20, 24, 18, 22, 30, 20, 24];
  static const _heights = [0.5, 0.8, 0.4, 0.95, 0.6, 0.75, 0.45, 0.88, 0.65, 1.0, 0.5, 0.82, 0.6, 0.72, 0.4, 0.9, 0.55, 0.7];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final window = Paint()..color = AppColors.amber;
    final total = _widths.fold<double>(0, (a, b) => a + b);
    final scale = size.width / total;
    var x = 0.0;

    for (var i = 0; i < _widths.length; i++) {
      final w = _widths[i] * scale;
      final h = _heights[i] * size.height * factor;
      final top = size.height - h;

      canvas.drawRRect(
        RRect.fromLTRBR(x, top, x + w - 2, size.height, const Radius.circular(2)),
        paint,
      );

      // Un toit pointu sur un bâtiment sur deux.
      if (i.isEven) {
        final roof = Path()
          ..moveTo(x - 1, top)
          ..lineTo(x + (w - 2) / 2, top - 7)
          ..lineTo(x + w - 1, top)
          ..close();
        canvas.drawPath(roof, paint);
      }

      if (lit && h > 12 && i % 3 != 1) {
        canvas.drawRRect(
          RRect.fromLTRBR(x + 4, top + 3, x + 7, top + 7, const Radius.circular(1)),
          window,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(x + w - 10, top + 3, x + w - 7, top + 7, const Radius.circular(1)),
          window,
        );
      }
      x += w;
    }
  }

  @override
  bool shouldRepaint(_SkylinePainter old) =>
      old.color != color || old.lit != lit || old.factor != factor;
}
