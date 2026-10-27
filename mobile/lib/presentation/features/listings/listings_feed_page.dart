import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/molecules/app_bottom_nav.dart';
import '../../components/molecules/listing_card.dart';
import '../../routes/app_routes.dart';
import 'listings_controller.dart';

const _green = Color(0xFF0F5C4D);

/// Accueil · A1 · liste des annonces.
class ListingsFeedPage extends StatelessWidget {
  const ListingsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ListingsController>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            // Logo + Se connecter
            Row(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Lofi',
                        style: AppTextStyles.title.copyWith(color: _green),
                      ),
                      TextSpan(
                        text: 'Soft',
                        style: AppTextStyles.title.copyWith(
                          color: const Color(0xFF2F8F6B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Get.snackbar(
                    'Bientôt',
                    'La connexion est dans un autre lot.',
                    snackPosition: SnackPosition.BOTTOM,
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Titre
            Text('Trouvez votre chez\u2011vous au Bénin.',
                style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.md),

            // Recherche
            TextField(
              decoration: InputDecoration(
                hintText: 'Ville ou quartier',
                hintStyle: AppTextStyles.caption,
                prefixIcon: const Icon(Icons.search_rounded, color: _green),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: const BorderSide(color: _green, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Choisis pour vous
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Choisis pour vous', style: AppTextStyles.bodyStrong),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Get.snackbar(
                          'Bientôt',
                          'La modification des critères arrive.',
                          snackPosition: SnackPosition.BOTTOM,
                        ),
                        child: const Text(
                          'Modifier',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Cotonou', style: AppTextStyles.caption),
                  Text('Appartement, Maison', style: AppTextStyles.caption),
                  Text('100 000 à 300 000', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Liste des annonces
            Obx(
                  () => Column(
                children: [
                  for (final item in controller.items) ...[
                    ListingCard(
                      title: item.title,
                      price: item.price,
                      location: item.location,
                      verified: item.verified,
                      isFavorite: controller.isFavorite(item.id),
                      onTap: () => Get.toNamed(
                        AppRoutes.listingDetails.replaceFirst(':id', item.id),
                      ),
                      onFavorite: () => controller.toggleFavorite(item.id),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: AppNavItems.tenant,
        currentIndex: 0,
        onTap: controller.goToTab,
      ),
    );
  }
}