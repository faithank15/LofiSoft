import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Pastille ronde avec les initiales (ex. « PA » pour Patrick Agossa).
///
/// ```dart
/// AppAvatar(initials: user.initials)
/// AppAvatar(initials: 'KM', size: 56)
/// ```
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.initials, this.size = 44});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: AppColors.green,
        ),
      ),
    );
  }
}
