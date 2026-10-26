import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../atoms/app_network_image.dart';
import '../atoms/housing_illustration.dart';
import '../atoms/status_text.dart';

/// Carte d'annonce : photo, prix par mois, type, lieu, badge « Propriétaire vérifié » et cœur.
///
/// ```dart
/// ListingCard(
///   title: 'Appartement · 3 pièces',
///   price: 350000,
///   location: 'Fidjrossè, Cotonou',
///   imageUrl: announcement.photos.firstOrNull?.url,
///   verified: true,
///   isFavorite: controller.isFavorite(id),
///   onTap: () => Get.toNamed('/listings/details/$id'),
///   onFavorite: () => controller.toggleFavorite(id),
/// )
/// ```
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.title,
    required this.price,
    required this.location,
    this.imageUrl,
    this.fallbackKind = HousingKind.building,
    this.verified = false,
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
  });

  final String title;

  /// Loyer mensuel en FCFA.
  final num price;
  final String location;

  /// Photo de l'annonce. Absente : une illustration est affichée.
  final String? imageUrl;
  final HousingKind fallbackKind;
  final bool verified;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  static const double _thumb = 112;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl == null || imageUrl!.isEmpty)
                  HousingIllustration(kind: fallbackKind, size: _thumb)
                else
                  AppNetworkImage(url: imageUrl!, width: _thumb, height: _thumb, radius: 16),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: CurrencyFormatter.number(price),
                                style: AppTextStyles.section,
                              ),
                              TextSpan(
                                text: ' FCFA/mois',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong.copyWith(fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                        if (verified) ...[
                          const SizedBox(height: AppSpacing.xs),
                          const StatusText('Propriétaire vérifié', kind: StatusKind.ok),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: AppSizes.tap,
                  height: AppSizes.tap,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 24,
                      color: isFavorite ? AppColors.clay : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
