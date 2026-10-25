import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Scène d'illustration d'un logement (maquettes E1 et E3).
///
/// Les maquettes utilisent des illustrations vectorielles très travaillées.
/// On en propose ici une version géométrique dessinée par Flutter (aucun
/// asset externe), fidèle à la palette et à la composition d'origine.
enum HousingSceneKind { chambre, studio, appartement, maison }

/// Illustration géométrique d'un logement.
///
/// Le fond est fourni par le parent (le composant ne dessine que la scène).
class HousingScene extends StatelessWidget {
  final HousingSceneKind kind;

  const HousingScene({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HousingScenePainter(kind: kind),
      size: Size.infinite,
    );
  }
}

class _HousingScenePainter extends CustomPainter {
  final HousingSceneKind kind;

  const _HousingScenePainter({required this.kind});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 0 || h <= 0) return;

    final Paint ground = Paint()..color = AppColors.greenDeep;
    final Paint grass = Paint()..color = AppColors.leaf;
    final Paint ink = Paint()..color = AppColors.ink;
    final Paint paper = Paint()..color = AppColors.paper;
    final Paint green = Paint()..color = AppColors.green;
    final Paint clay = Paint()..color = AppColors.clay;
    final Paint amber = Paint()..color = AppColors.amber;
    final Paint terracotta = Paint()..color = AppColors.terracotta;
    final Paint trunk = Paint()..color = AppColors.clayDeep;

    // Sol : bande sombre + liseré vert.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), ground);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.83, w, h * 0.03), grass);

    switch (kind) {
      case HousingSceneKind.chambre:
      case HousingSceneKind.studio:
        _paintRoom(canvas, w, h, paper, ink, green, clay, trunk);
      case HousingSceneKind.appartement:
        _paintBuilding(canvas, w, h, terracotta, ink, green, amber, ground);
      case HousingSceneKind.maison:
        _paintHouse(canvas, w, h, paper, green, clay, trunk);
    }
  }

  /// Scène « chambre / studio » : une pièce vue de face.
  void _paintRoom(
    Canvas canvas,
    double w,
    double h,
    Paint paper,
    Paint ink,
    Paint green,
    Paint clay,
    Paint trunk,
  ) {
    // Mur + poutre.
    canvas.drawRect(Rect.fromLTWH(w * 0.30, h * 0.28, w * 0.40, h * 0.58), paper);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.22, w * 0.44, h * 0.07),
        Radius.circular(h * 0.03),
      ),
      ink,
    );
    // Fenêtre.
    canvas.drawRect(Rect.fromLTWH(w * 0.35, h * 0.38, w * 0.13, h * 0.18), green);
    // Porte.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.52, h * 0.50, w * 0.13, h * 0.36),
        Radius.circular(w * 0.01),
      ),
      clay,
    );
    // Arbre.
    canvas.drawRect(Rect.fromLTWH(w * 0.78, h * 0.60, w * 0.02, h * 0.26), trunk);
    canvas.drawCircle(Offset(w * 0.79, h * 0.56), h * 0.10, green);
    canvas.drawCircle(Offset(w * 0.84, h * 0.62), h * 0.07, green);
  }

  /// Scène « appartement » : façade d'immeuble.
  void _paintBuilding(
    Canvas canvas,
    double w,
    double h,
    Paint terracotta,
    Paint ink,
    Paint green,
    Paint amber,
    Paint ground,
  ) {
    // Façade + toit.
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.22, w * 0.44, h * 0.64), terracotta);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.13, w * 0.50, h * 0.07),
        Radius.circular(h * 0.03),
      ),
      ink,
    );
    // Fenêtres : 4 colonnes × 3 rangées, une ambre pour casser la monotonie.
    const double cellW = 0.055;
    const double cellH = 0.075;
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 4; col++) {
        final Paint paint = (row == 1 && col == 1) ? amber : green;
        canvas.drawRect(
          Rect.fromLTWH(
            w * (0.32 + col * 0.09),
            h * (0.28 + row * 0.13),
            w * cellW,
            h * cellH,
          ),
          paint,
        );
      }
    }
    // Entrée.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.68, w * 0.10, h * 0.18),
        Radius.circular(w * 0.01),
      ),
      ground,
    );
  }

  /// Scène « maison » : maison à toit pentu.
  void _paintHouse(
    Canvas canvas,
    double w,
    double h,
    Paint paper,
    Paint green,
    Paint clay,
    Paint trunk,
  ) {
    // Corps de la maison.
    canvas.drawRect(Rect.fromLTWH(w * 0.22, h * 0.44, w * 0.56, h * 0.42), paper);
    // Toit.
    final Path roof = Path()
      ..moveTo(w * 0.18, h * 0.44)
      ..lineTo(w * 0.50, h * 0.24)
      ..lineTo(w * 0.82, h * 0.44)
      ..close();
    canvas.drawPath(roof, green);
    // Fenêtres.
    canvas.drawRect(Rect.fromLTWH(w * 0.29, h * 0.56, w * 0.10, h * 0.12), green);
    canvas.drawRect(Rect.fromLTWH(w * 0.60, h * 0.56, w * 0.10, h * 0.12), green);
    // Porte.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.44, h * 0.62, w * 0.12, h * 0.24),
        Radius.circular(w * 0.01),
      ),
      clay,
    );
    // Arbre.
    canvas.drawRect(Rect.fromLTWH(w * 0.86, h * 0.62, w * 0.02, h * 0.24), trunk);
    canvas.drawCircle(Offset(w * 0.87, h * 0.58), h * 0.09, green);
  }

  @override
  bool shouldRepaint(covariant _HousingScenePainter oldDelegate) {
    return oldDelegate.kind != kind;
  }
}
