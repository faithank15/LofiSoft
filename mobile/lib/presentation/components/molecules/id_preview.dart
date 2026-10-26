import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_network_image.dart';

/// Aperçu côte à côte de la pièce d'identité et du selfie d'un propriétaire à vérifier.
/// Sans image (pas encore reçue), un fond neutre avec une icône est affiché.
///
/// ```dart
/// IdPreview(idImageUrl: request.idUrl, selfieUrl: request.selfieUrl)
/// ```
class IdPreview extends StatelessWidget {
  const IdPreview({super.key, this.idImageUrl, this.selfieUrl, this.height = 108});

  final String? idImageUrl;
  final String? selfieUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Tile(label: 'Pièce d’identité', url: idImageUrl, icon: Icons.badge_outlined, height: height)),
        const SizedBox(width: 10),
        Expanded(child: _Tile(label: 'Selfie', url: selfieUrl, icon: Icons.face_outlined, height: height)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.url, required this.icon, required this.height});

  final String label;
  final String? url;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: (url == null || url!.isEmpty)
                      ? ColoredBox(
                          color: AppColors.sand,
                          child: Center(child: Icon(icon, size: 36, color: AppColors.muted)),
                        )
                      : AppNetworkImage(url: url!, width: width, height: height),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      child: Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
