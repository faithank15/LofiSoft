import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../atoms/app_network_image.dart';
import '../atoms/dashed_border.dart';

/// Une photo de l'annonce : soit déjà en ligne (`url`), soit choisie sur le téléphone (`localPath`).
class PhotoItem {
  const PhotoItem({this.url, this.localPath});

  final String? url;
  final String? localPath;
}

/// Rangée horizontale de photos avec bouton d'ajout (jusqu'à `max` photos).
/// Composant passif : le choix dans la galerie et l'envoi sont faits par le contrôleur.
///
/// ```dart
/// Obx(() => PhotoPicker(
///   photos: controller.photos.toList(),
///   onAdd: controller.pickPhoto,
///   onRemove: controller.removePhoto,
/// ))
/// ```
class PhotoPicker extends StatelessWidget {
  const PhotoPicker({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    this.max = 10,
  });

  final List<PhotoItem> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final int max;

  static const double _tile = 100;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Photos', style: AppTextStyles.label),
            Text('${photos.length} sur $max', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: _tile,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < photos.length; i++) ...[
                _PhotoTile(item: photos[i], isMain: i == 0, onRemove: () => onRemove(i)),
                const SizedBox(width: 10),
              ],
              if (photos.length < max)
                Semantics(
                  button: true,
                  label: 'Ajouter une photo',
                  child: GestureDetector(
                    onTap: onAdd,
                    child: const SizedBox(
                      width: 64,
                      height: _tile,
                      child: DashedBorder(
                        radius: 16,
                        child: Center(child: Icon(Icons.add_rounded, size: 28, color: AppColors.green)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.item, required this.isMain, required this.onRemove});

  final PhotoItem item;
  final bool isMain;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (item.localPath != null) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(item.localPath!),
          width: PhotoPicker._tile,
          height: PhotoPicker._tile,
          fit: BoxFit.cover,
          cacheWidth: 300,
        ),
      );
    } else {
      image = AppNetworkImage(
        url: item.url ?? '',
        width: PhotoPicker._tile,
        height: PhotoPicker._tile,
        radius: 16,
      );
    }
    return SizedBox(
      width: PhotoPicker._tile,
      height: PhotoPicker._tile,
      child: Stack(
        children: [
          Positioned.fill(child: image),
          if (isMain)
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
                    'Principale',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 2,
            top: 2,
            child: SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Retirer la photo',
                onPressed: onRemove,
                icon: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.surface),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
