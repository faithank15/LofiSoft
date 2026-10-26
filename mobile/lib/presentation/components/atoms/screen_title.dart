import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// En-tête de page : titre et sous-titre.
///
/// ```dart
/// ScreenTitle(title: 'Mes logements')
/// ScreenTitle(title: 'Où cherchez-vous ?', subtitle: 'Choisissez une ou plusieurs villes.')
/// ```
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title, this.subtitle, this.large = true});

  final String title;
  final String? subtitle;

  /// `true` : 28 px (écrans d'onboarding, accueil). `false` : 24 px.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: large ? AppTextStyles.display : AppTextStyles.title),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle!, style: AppTextStyles.body.copyWith(color: AppTextStyles.subtitle.color)),
        ],
      ],
    );
  }
}
