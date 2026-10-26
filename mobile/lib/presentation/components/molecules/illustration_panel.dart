import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/skyline_band.dart';

/// Grand panneau coloré qui présente une illustration, avec un titre et une légende.
///
/// ```dart
/// IllustrationPanel(
///   illustration: ChoiceIllustration(kind: ChoiceKind.owner, size: 160),
///   title: 'Suivez vos loyers',
///   caption: 'Qui a payé, qui est en retard.',
/// )
/// ```
class IllustrationPanel extends StatelessWidget {
  const IllustrationPanel({
    super.key,
    required this.illustration,
    this.title,
    this.caption,
    this.height = 300,
  });

  final Widget illustration;
  final String? title;
  final String? caption;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.panel),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: AppColors.greenDeep,
          child: Stack(
            children: [
              const Positioned(left: 0, right: 0, bottom: 0, child: SkylineBand(height: 70)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Center(child: illustration)),
                    if (title != null)
                      Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.section.copyWith(color: AppColors.surface),
                      ),
                    if (caption != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        caption!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.mint.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
