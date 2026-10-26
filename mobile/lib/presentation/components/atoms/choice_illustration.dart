import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Profils illustrés dans l'onboarding.
enum ChoiceKind {
  /// Une maison et une clé : « Je cherche un logement ».
  tenant,

  /// Un immeuble aux fenêtres de couleur : « Je loue mes logements ».
  owner,
}

/// Illustration vectorielle d'un choix de profil (se redimensionne sans perte).
///
/// ```dart
/// ChoiceIllustration(kind: ChoiceKind.tenant, size: 120)
/// ```
class ChoiceIllustration extends StatelessWidget {
  const ChoiceIllustration({super.key, required this.kind, this.size = 120});

  final ChoiceKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ChoicePainter(kind)),
      ),
    );
  }
}

class _ChoicePainter extends CustomPainter {
  const _ChoicePainter(this.kind);

  final ChoiceKind kind;

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
      case ChoiceKind.tenant:
        // Maison
        rect(w * 0.14, h * 0.44, w * 0.62, h * 0.42, AppColors.paper, w * 0.03);
        final roof = Path()
          ..moveTo(w * 0.08, h * 0.46)
          ..lineTo(w * 0.45, h * 0.14)
          ..lineTo(w * 0.82, h * 0.46)
          ..close();
        canvas.drawPath(roof, fill(AppColors.green));
        rect(w * 0.38, h * 0.62, w * 0.14, h * 0.24, AppColors.greenDeep, w * 0.02);
        rect(w * 0.2, h * 0.54, w * 0.12, h * 0.1, AppColors.leaf, w * 0.015);
        // Clé ambre
        final key = fill(AppColors.amber);
        canvas.drawCircle(Offset(w * 0.78, h * 0.72), w * 0.1, key);
        canvas.drawCircle(Offset(w * 0.78, h * 0.72), w * 0.045, fill(AppColors.greenDeep));
        rect(w * 0.76, h * 0.8, w * 0.04, h * 0.14, AppColors.amber, w * 0.01);
        rect(w * 0.8, h * 0.86, w * 0.07, h * 0.035, AppColors.amber, w * 0.01);
        rect(0, h * 0.9, w, h * 0.04, AppColors.leaf, w * 0.02);
      case ChoiceKind.owner:
        rect(w * 0.12, h * 0.1, w * 0.76, h * 0.78, AppColors.paper, w * 0.04);
        rect(w * 0.06, h * 0.05, w * 0.88, h * 0.07, AppColors.ink, w * 0.02);
        rect(w * 0.22, h * 0.22, w * 0.24, h * 0.26, AppColors.fillPaid, w * 0.03);
        rect(w * 0.54, h * 0.22, w * 0.24, h * 0.26, AppColors.fillPartial, w * 0.03);
        rect(w * 0.38, h * 0.54, w * 0.24, h * 0.2, AppColors.fillLate, w * 0.03);
        rect(w * 0.43, h * 0.76, w * 0.14, h * 0.12, AppColors.greenDeep, w * 0.02);
        rect(0, h * 0.9, w, h * 0.04, AppColors.leaf, w * 0.02);
    }
  }

  @override
  bool shouldRepaint(_ChoicePainter old) => old.kind != kind;
}
