import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Séparateur visuel fin standardisé LofiSoft.
///
/// Respecte la couleur de trait officielle [AppColors.line] avec une épaisseur
/// unitaire de 1.0 pixel, disponible en horizontal ou vertical.
class AppDivider extends StatelessWidget {
  final Color color;
  final double thickness;
  final double indent;
  final double endIndent;
  final Axis axis;
  final double? length;

  const AppDivider({
    super.key,
    this.color = AppColors.line,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.axis = Axis.horizontal,
    this.length,
  });

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) {
      return Container(
        width: thickness,
        height: length,
        margin: EdgeInsets.only(top: indent, bottom: endIndent),
        color: color,
      );
    }

    return Container(
      height: thickness,
      width: length,
      margin: EdgeInsets.only(left: indent, right: endIndent),
      color: color,
    );
  }
}
