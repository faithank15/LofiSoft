import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_wordmark.dart';
import '../../components/molecules/app_bottom_nav.dart';
import '../../components/molecules/listing_card.dart';
import '../../routes/app_routes.dart';
import '../../shared/empty_view.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'listings_controller.dart';

/// Accueil · A1 · liste des annonces.
class ListingsFeedPage extends StatefulWidget {
  const ListingsFeedPage({super.key});

  @override
  State<ListingsFeedPage> createState() => _ListingsFeedPageState();
}

class _ListingsFeedPageState extends State<ListingsFeedPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final controller = Get.find<ListingsController>();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) controller.loadMore();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: controller.loadFeed,
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Row(
                children: [
                  const AppWordmark(size: 24),
                  const Spacer(),
                  if (!controller.hasSession)
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.login),
                      child: Text(
                        'Se connecter',
                        style: AppTextStyles.bodyStrong.copyWith(color: AppColors.green),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Trouvez votre chez‑vous au Bénin.', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: controller.search,
                decoration: InputDecoration(
                  hintText: 'Ville ou quartier',
                  hintStyle: AppTextStyles.caption,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.green),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  border: _border(AppColors.line, 1),
                  enabledBorder: _border(AppColors.line, 1),
                  focusedBorder: _border(AppColors.green, 2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PreferencesCard(controller: controller),
              _Body(controller: controller),
            ],
          ),
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

/// « Choisis pour vous » : rappelle les critères de l'onboarding appliqués au fil.
class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.controller});

  final ListingsController controller;

  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    final prefs = controller.preferences.value;
    if (prefs.isEmpty || !controller.usePreferences.value) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                  onTap: controller.editPreferences,
                  child: Text(
                    'Modifier',
                    style: AppTextStyles.bodyStrong.copyWith(color: AppColors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (prefs.city.isNotEmpty) Text(prefs.city, style: AppTextStyles.caption),
            if (prefs.types.isNotEmpty) Text(prefs.types.join(', '), style: AppTextStyles.caption),
            if (prefs.budgetLabel.isNotEmpty)
              Text(prefs.budgetLabel.replaceAll(' FCFA', ''), style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final ListingsController controller;

  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    switch (controller.status.value) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxl),
          child: SizedBox(height: 160, child: LoadingView()),
        );
      case LoadStatus.failure:
        return SizedBox(
          height: 300,
          child: ErrorView(
            message: controller.errorMessage.value ?? 'Chargement impossible.',
            onRetry: controller.loadFeed,
          ),
        );
      case LoadStatus.loaded:
        break;
    }

    if (controller.items.isEmpty) {
      return Column(
        children: [
          const SizedBox(
            height: 220,
            child: EmptyView(
              label: 'Aucune annonce pour ces critères',
              icon: Icons.search_off_rounded,
            ),
          ),
          if (controller.usePreferences.value && !controller.preferences.value.isEmpty)
            AppButton(
              label: 'Voir tous les logements',
              variant: AppButtonVariant.outline,
              onPressed: controller.showAll,
            ),
        ],
      );
    }

    return Column(
      children: [
        for (final item in controller.items) ...[
          ListingCard(
            title: item.title,
            price: item.rent,
            location: item.location,
            imageUrl: item.firstPhoto,
            verified: item.verified,
            isFavorite: controller.isFavorite(item.id),
            onTap: () => Get.toNamed(AppRoutes.listingDetails.replaceFirst(':id', item.id)),
            onFavorite: () => controller.toggleFavorite(item),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (controller.loadingMore.value)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(height: 32, child: LoadingView()),
          ),
      ],
    );
  }
}
