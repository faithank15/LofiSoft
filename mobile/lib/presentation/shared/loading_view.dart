import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Chargement centré, à placer dans le corps d'une page.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 3),
    );
  }
}
