import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Types de logements dessinés.
enum HousingKind { building, villa, studio }

/// Illustration vectorielle d'un logement. Sert d'image de remplacement quand une annonce
/// n'a pas encore de photo, et de visuel dans l'onboarding. Se redimensionne sans perte.
///
/// ```dart
/// HousingIllustration(kind: HousingKind.building, size: 112)
/// ```
class HousingIllustration extends StatelessWidget {
  const HousingIllustration({super.key, required this.kind, this.size = 112, this.radius = 16});

  final HousingKind kind;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _HousingPainter(kind)),
        ),
      ),
    );
  }
}

class _HousingPainter extends CustomPainter {
  const _HousingPainter(this.kind);

  final HousingKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Paint fill(Color c) => Paint()..color = c;
    void rect(double x, double y, double rw, double rh, Color c, [double r = 0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, rw, rh), Radius.circular(r)),
        fill(c),
      );
    }

    switch (kind) {
      case HousingKind.building:
        rect(0, 0, w, h, AppColors.mint);
        rect(w * 0.16, h * 0.12, w * 0.68, h * 0.78, const Color(0xFFE9B9A3), w * 0.02);
        rect(w * 0.12, h * 0.08, w * 0.76, h * 0.06, AppColors.ink, w * 0.02);
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 3; col++) {
            final lit = row == 1 && col == 1;
            rect(
              w * (0.24 + col * 0.19),
              h * (0.22 + row * 0.18),
              w * 0.13,
              h * 0.11,
              lit ? AppColors.amber : AppColors.green,
              w * 0.015,
            );
          }
        }
        rect(w * 0.43, h * 0.74, w * 0.14, h * 0.16, AppColors.greenDeep, w * 0.015);
        rect(0, h * 0.9, w, h * 0.1, AppColors.greenDeep);
      case HousingKind.villa:
        rect(0, 0, w, h, AppColors.sand);
        rect(w * 0.08, h * 0.5, w * 0.84, h * 0.4, AppColors.paper);
        final roof = Path()
          ..moveTo(w * 0.04, h * 0.52)
          ..lineTo(w * 0.2, h * 0.26)
          ..lineTo(w * 0.8, h * 0.26)
          ..lineTo(w * 0.96, h * 0.52)
          ..close();
        canvas.drawPath(roof, fill(const Color(0xFF2F6F5E)));
        rect(w * 0.16, h * 0.6, w * 0.16, h * 0.14, AppColors.green, w * 0.015);
        rect(w * 0.42, h * 0.6, w * 0.16, h * 0.14, AppColors.green, w * 0.015);
        rect(w * 0.68, h * 0.62, w * 0.14, h * 0.28, AppColors.clay, w * 0.015);
        rect(0, h * 0.9, w, h * 0.1, AppColors.greenDeep);
      case HousingKind.studio:
        rect(0, 0, w, h, const Color(0xFFF0D3C3));
        rect(w * 0.18, h * 0.42, w * 0.64, h * 0.48, AppColors.paper);
        rect(w * 0.12, h * 0.36, w * 0.76, h * 0.07, AppColors.ink, w * 0.02);
        rect(w * 0.26, h * 0.52, w * 0.18, h * 0.14, AppColors.green, w * 0.015);
        rect(w * 0.56, h * 0.5, w * 0.16, h * 0.4, AppColors.clay, w * 0.015);
        rect(0, h * 0.9, w, h * 0.1, AppColors.greenDeep);
    }
  }

  @override
  bool shouldRepaint(_HousingPainter old) => old.kind != kind;
}
