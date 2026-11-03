import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/cloudinary.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = 0,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final pixels = ((width * dpr / 100).ceil() * 100).clamp(100, 2000).toInt();
    final optimized = Cloudinary.optimize(
      url,
      width: pixels,
      height: (height * dpr).round(),
    );

    final placeholder = ColoredBox(
      color: AppColors.sand,
      child: SizedBox(width: width, height: height),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: optimized,
          fit: fit,
          memCacheWidth: pixels,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => placeholder,
          errorWidget: (context, url, error) => ColoredBox(
            color: AppColors.sand,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.muted.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
