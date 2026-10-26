import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Cadre en pointillés autour d'un contenu (zone « ajouter une photo », boîte du code logement).
///
/// ```dart
/// DashedBorder(radius: 22, color: AppColors.green, child: ...)
/// ```
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.radius = 16,
    this.color = AppColors.green,
    this.strokeWidth = 2,
    this.background,
  });

  final Widget child;
  final double radius;
  final Color color;
  final double strokeWidth;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedPainter(radius: radius, color: color, strokeWidth: strokeWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({required this.radius, required this.color, required this.strokeWidth});

  final double radius;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    const dash = 7.0;
    const gap = 5.0;
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.radius != radius || old.color != color || old.strokeWidth != strokeWidth;
}
