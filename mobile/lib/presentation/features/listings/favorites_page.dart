import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/molecules/app_bottom_nav.dart';
import '../../components/molecules/listing_card.dart';
import '../../routes/app_routes.dart';
import '../../shared/empty_view.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'listings_controller.dart';

/// Favoris · A4 · annonces enregistrées.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final controller = Get.find<ListingsController>();

  @override
  void initState() {
    super.initState();
    controller.loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
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

          return RefreshIndicator(
            color: AppColors.green,
            onRefresh: controller.loadFavorites,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Text('Favoris', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.md),
                ..._content(favorites),
              ],
            ),
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

  List<Widget> _content(List favorites) {
    switch (controller.favoritesStatus.value) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const [SizedBox(height: 240, child: LoadingView())];
      case LoadStatus.failure:
        return [
          SizedBox(
            height: 300,
            child: ErrorView(
              message: controller.errorMessage.value ?? 'Chargement impossible.',
              onRetry: controller.loadFavorites,
            ),
          ),
        ];
      case LoadStatus.loaded:
        break;
    }
    if (favorites.isEmpty) {
      return [
        SizedBox(
          height: 240,
          child: EmptyView(
            label: controller.hasSession
                ? 'Touchez le cœur d’une annonce pour la retrouver ici.'
                : 'Connectez-vous pour retrouver vos favoris.',
            icon: Icons.favorite_border_rounded,
          ),
        ),
      ];
    }
    return [
      for (final item in controller.favorites) ...[
        ListingCard(
          title: item.title,
          price: item.rent,
          location: item.location,
          imageUrl: item.firstPhoto,
          verified: item.verified,
          isFavorite: true,
          onTap: () => Get.toNamed(AppRoutes.listingDetails.replaceFirst(':id', item.id)),
          onFavorite: () => controller.toggleFavorite(item),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }
}
