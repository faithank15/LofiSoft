import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../atoms/skyline_band.dart';

class RentGauge extends StatelessWidget {
  const RentGauge({
    super.key,
    required this.label,
    required this.received,
    required this.expected,
  });

  final String label;
  final num received;
  final num expected;

  static const _height = 52.0;
  static const _duration = Duration(milliseconds: 2200);
  static const _track = Color(0xFF072B24);
  static const _ink = Color(0xFF0A3D33);
  static const _sun = Color(0xFFF2B134);

  double get _value =>
      expected <= 0 ? 0 : (received / expected).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final target = _value;
    final soft = AppColors.mint.withValues(alpha: 0.85);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: soft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(target * 100).round()} %',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.surface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: target),
              duration: _duration,
              curve: const Cubic(0.16, 1, 0.3, 1),
              builder: (context, v, _) {
                final fillWidth = width * v;
                final shown = target == 0 ? 0 : received * (v / target);

                return SizedBox(
                  height: _height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Positioned.fill(child: Container(color: _track)),
                            const Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: SkylineBand(
                                height: _height,
                                color: Color(0x1AFFFFFF),
                              ),
                            ),
                            Positioned.fill(
                              child: _amountText(
                                shown,
                                const Color(0xFFCFE6DB),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: fillWidth,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFF7F3EA),
                                      Color(0xFFF6DFA6),
                                    ],
                                    stops: [0.55, 1],
                                  ),
                                ),
                                child: ClipRect(
                                  child: OverflowBox(
                                    alignment: Alignment.centerLeft,
                                    minWidth: width,
                                    maxWidth: width,
                                    child: Stack(
                                      children: [
                                        const Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: SkylineBand(
                                            height: _height,
                                            color: Color(0x210A3D33),
                                            litWindows: true,
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: _amountText(shown, _ink),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: fillWidth - 10,
                        top: -8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _sun,
                            shape: BoxShape.circle,
                            border: Border.all(color: _ink, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _amountText(num amount, Color color) {
    final big = AppTextStyles.section.copyWith(
      color: color,
      fontSize: 21,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          softWrap: false,
          maxLines: 1,
          TextSpan(
            style: big,
            children: [
              TextSpan(text: CurrencyFormatter.number(amount)),
              TextSpan(
                text: '  /  ',
                style: big.copyWith(color: color.withValues(alpha: 0.6)),
              ),
              TextSpan(text: CurrencyFormatter.number(expected)),
              TextSpan(
                text: ' ${AppConstants.currency}',
                style: big.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
