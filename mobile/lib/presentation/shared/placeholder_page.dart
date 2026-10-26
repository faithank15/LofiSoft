import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Page TEMPORAIRE pour les routes que les autres membres n'ont pas encore écrites.
/// À supprimer de app_pages.dart dès que la vraie page existe.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text('Écran à venir', style: AppTextStyles.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
