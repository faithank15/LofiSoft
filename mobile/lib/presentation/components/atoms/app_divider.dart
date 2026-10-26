import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Séparateur fin. `indent` décale le début du trait (pour aligner sur du texte).
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: const SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(color: AppColors.line),
      ),
    );
  }
}
