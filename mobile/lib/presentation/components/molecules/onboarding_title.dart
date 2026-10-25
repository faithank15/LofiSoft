import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Titre + sous-titre d'un écran d'onboarding (maquettes E2 → E4).
///
/// Titre 34 / 800, sous-titre 17, alignés à gauche comme sur les maquettes.
class OnboardingTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;

  const OnboardingTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleColor = AppColors.ink,
    this.subtitleColor = AppColors.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.display.copyWith(
            fontSize: 34,
            height: 1.1,
            letterSpacing: -0.85,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(
            fontSize: 17,
            height: 1.5,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }
}
