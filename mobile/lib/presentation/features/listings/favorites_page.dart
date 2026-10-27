import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/molecules/app_bottom_nav.dart';
import '../../components/molecules/listing_card.dart';
import '../../routes/app_routes.dart';
import 'listings_controller.dart';

/// Favoris · A4 · annonces enregistrées.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ListingsController>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Obx(() {
          final favorites = controller.favorites;
          final count = favorites.length;
          final subtitle = count == 0
              ? 'Aucun logement enregistré'
              : '$count logement${count > 1 ? 's' : ''} '
              'enregistré${count > 1 ? 's' : ''}';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text('Favoris', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.md),
              if (count == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      'Touchez le cœur d\u2019une annonce pour la retrouver ici.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
              for (final item in favorites) ...[
                ListingCard(
                  title: item.title,
                  price: item.price,
                  location: item.location,
                  verified: item.verified,
                  isFavorite: true,
                  onTap: () => Get.toNamed(
                    AppRoutes.listingDetails.replaceFirst(':id', item.id),
                  ),
                  onFavorite: () => controller.toggleFavorite(item.id),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }),
      ),
      bottomNavigationBar: AppBottomNav(
        items: AppNavItems.tenant,
        currentIndex: 1,
        onTap: controller.goToTab,
      ),
    );
  }
}