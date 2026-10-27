import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum ProfileKind { locataire, proprietaire }

/// Illustration des cartes de profil de l'écran E1 (maison / immeuble).
///
/// Dessinée dans le repère SVG de la maquette (150×120 et 300×138) puis mise à
/// l'échelle en gardant le rapport d'aspect : elle ne se déforme jamais.
class ProfileIllustration extends StatelessWidget {
  final ProfileKind kind;
  final double width;

  const ProfileIllustration({super.key, required this.kind, this.width = 150});

  Size get _viewBox => kind == ProfileKind.locataire
      ? const Size(150, 120)
      : const Size(300, 138);

  @override
  Widget build(BuildContext context) {
    final Size box = _viewBox;
    return CustomPaint(
      size: Size(width, width * box.height / box.width),
      painter: _ProfilePainter(kind: kind, viewBox: box),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final ProfileKind kind;
  final Size viewBox;

  const _ProfilePainter({required this.kind, required this.viewBox});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / viewBox.width, size.height / viewBox.height);
    if (kind == ProfileKind.locataire) {
      _paintHouse(canvas);
    } else {
      _paintBuilding(canvas);
    }
  }

  void _rect(Canvas c, double x, double y, double w, double h, double r,
      Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      Paint()..color = color,
    );
  }

  void _paintHouse(Canvas c) {
    _rect(c, 10, 48, 96, 64, 4, AppColors.paper);
    c.drawPath(
      Path()
        ..moveTo(2, 52)
        ..lineTo(58, 14)
        ..lineTo(114, 52)
        ..close(),
      Paint()..color = AppColors.ink,
    );
    _rect(c, 26, 68, 22, 22, 3, AppColors.green);
    _rect(c, 66, 66, 24, 46, 3, AppColors.clay);
    c.drawCircle(const Offset(118, 78), 15, Paint()..color = AppColors.amber);
    c.drawCircle(
        const Offset(118, 78), 6, Paint()..color = AppColors.greenDeep);
    _rect(c, 127, 75, 22, 7, 3, AppColors.amber);
    _rect(c, 138, 82, 6, 10, 2, AppColors.amber);
  }

  void _paintBuilding(Canvas c) {
    _rect(c, 21, 14, 258, 108, 6, AppColors.paper);
    _rect(c, 13, 6, 274, 12, 4, AppColors.ink);
    _rect(c, 43, 30, 62, 52, 6, AppColors.leaf);
    _rect(c, 119, 30, 62, 52, 6, AppColors.fillPartial);
    _rect(c, 195, 30, 62, 52, 6, AppColors.clay);
    _rect(c, 132, 96, 36, 26, 3, AppColors.greenDeep);
    _rect(c, 0, 128, 300, 10, 5, AppColors.leaf);
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) =>
      old.kind != kind || old.viewBox != viewBox;
}
