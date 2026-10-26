import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Types d'illustrations intégrées dédiées à l'onboarding propriétaire.
enum IllustrationType {
  /// Vue d'ensemble de l'immeuble avec fenêtres colorées et légende de statut (Écran E5).
  ownerWelcome,

  /// Bouclier de certification et coche de sécurité (Écran E7).
  ownerVerification,
}

/// Panneau illustré vectoriel haute fidélité pour l'onboarding propriétaire.
///
/// Reproduit fidèlement les compositions graphiques des maquettes E5 et E7
/// sans dépendance de fichiers d'images externes, garantissant un affichage
/// net et performant.
class OwnerIllustrationPanel extends StatelessWidget {
  const OwnerIllustrationPanel({super.key, required this.type, this.height});

  final IllustrationType type;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      IllustrationType.ownerWelcome => _buildOwnerWelcomePanel(),
      IllustrationType.ownerVerification => _buildOwnerVerificationPanel(),
    };
  }

  Widget _buildOwnerWelcomePanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 300,
          height: height ?? 204,
          child: CustomPaint(painter: _BuildingIllustrationPainter()),
        ),
        const SizedBox(height: AppSpacing.md),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusLegendBadge(color: AppColors.leaf, label: 'Payé'),
            SizedBox(width: AppSpacing.lg),
            _StatusLegendBadge(color: AppColors.amber, label: 'Partiel'),
            SizedBox(width: AppSpacing.lg),
            _StatusLegendBadge(color: AppColors.clay, label: 'En retard'),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerVerificationPanel() {
    return Container(
      height: height ?? 270,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 150,
        height: 170,
        child: CustomPaint(painter: _ShieldIllustrationPainter()),
      ),
    );
  }
}

class _StatusLegendBadge extends StatelessWidget {
  const _StatusLegendBadge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Peintre vectoriel reproduisant fidèlement le SVG de l'immeuble de loyers (Écran E5).
class _BuildingIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 300.0;
    final scaleY = size.height / 204.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final paintPaper = Paint()..color = AppColors.paper;
    final paintRoof = Paint()..color = AppColors.ink;
    final paintDoor = Paint()..color = AppColors.greenDeep;
    final paintGround = Paint()..color = AppColors.leaf;
    final paintPaid = Paint()..color = AppColors.leaf;
    final paintPartial = Paint()..color = AppColors.amber;
    final paintLate = Paint()..color = AppColors.clay;
    final paintFree = Paint()..color = AppColors.sand;

    // Corps du bâtiment
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(21, 14, 258, 174),
        const Radius.circular(6),
      ),
      paintPaper,
    );

    // Toiture
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 6, 274, 12),
        const Radius.circular(4),
      ),
      paintRoof,
    );

    // Étage 1 : Fenêtres
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 30, 62, 52),
        const Radius.circular(6),
      ),
      paintPaid,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(119, 30, 62, 52),
        const Radius.circular(6),
      ),
      paintPartial,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(195, 30, 62, 52),
        const Radius.circular(6),
      ),
      paintLate,
    );

    // Étage 2 : Fenêtres
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 96, 62, 52),
        const Radius.circular(6),
      ),
      paintPaid,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(119, 96, 62, 52),
        const Radius.circular(6),
      ),
      paintPaid,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(195, 96, 62, 52),
        const Radius.circular(6),
      ),
      paintFree,
    );

    // Porte d'entrée
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(132, 162, 36, 26),
        const Radius.circular(3),
      ),
      paintDoor,
    );

    // Sol verdoyant
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 194, 300, 10),
        const Radius.circular(5),
      ),
      paintGround,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Peintre vectoriel reproduisant le bouclier de vérification (Écran E7).
class _ShieldIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 150.0;
    final scaleY = size.height / 170.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Bouclier extérieur
    final outerPath = Path()
      ..moveTo(75, 8)
      ..lineTo(133, 30)
      ..lineTo(133, 78)
      ..cubicTo(133, 116, 107, 144, 75, 162)
      ..cubicTo(43, 144, 17, 116, 17, 78)
      ..lineTo(17, 30)
      ..close();

    final outerPaint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, outerPaint);

    // Bouclier intérieur
    final innerPath = Path()
      ..moveTo(75, 24)
      ..lineTo(119, 41)
      ..lineTo(119, 78)
      ..cubicTo(119, 107, 100, 129, 75, 144)
      ..cubicTo(50, 129, 31, 107, 31, 78)
      ..lineTo(31, 41)
      ..close();

    final innerPaint = Paint()
      ..color = AppColors.greenDeep
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, innerPaint);

    // Coche de validation blanche
    final checkPath = Path()
      ..moveTo(52, 84)
      ..lineTo(69, 101)
      ..lineTo(100, 64);

    final checkPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(checkPath, checkPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
