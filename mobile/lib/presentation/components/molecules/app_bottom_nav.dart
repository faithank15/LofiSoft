import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Un onglet de la barre de navigation.
class NavItem {
  const NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Les onglets de chaque profil.
abstract final class AppNavItems {
  /// Visiteur et locataire.
  static const tenant = [
    NavItem(icon: Icons.home_outlined, label: 'Accueil'),
    NavItem(icon: Icons.favorite_border_rounded, label: 'Favoris'),
    NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Mon loyer'),
    NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
  ];

  static const owner = [
    NavItem(icon: Icons.home_outlined, label: 'Accueil'),
    NavItem(icon: Icons.apartment_rounded, label: 'Logements'),
    NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Loyers'),
    NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
  ];

  static const admin = [
    NavItem(icon: Icons.flag_outlined, label: 'Signalements'),
    NavItem(icon: Icons.verified_user_outlined, label: 'Vérifications'),
    NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
  ];
}

/// Barre de navigation du bas. L'onglet actif a une pastille menthe.
///
/// ```dart
/// AppBottomNav(items: AppNavItems.tenant, currentIndex: 0, onTap: controller.goToTab)
/// ```
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.up,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.bottomNav,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.green : AppColors.muted;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 60,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.mint : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, size: 24, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.nav.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
