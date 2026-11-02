import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../shared/empty_view.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'admin_controller.dart';
import 'admin_dialogs.dart';

/// Squelette commun de D1 et D2 : titre, sous-titre, liste tirable pour actualiser,
/// états chargement / erreur / vide, et barre du bas.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.controller,
    required this.navIndex,
    required this.title,
    required this.subtitle,
    required this.itemCount,
    required this.itemBuilder,
    required this.emptyLabel,
    required this.emptyHint,
    required this.emptyIcon,
  });

  final AdminController controller;
  final int navIndex;
  final String title;

  /// Évalué dans un `Obx` : peut lire des valeurs observables.
  final String Function() subtitle;
  final int Function() itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final String emptyLabel;
  final String emptyHint;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Obx(() {
          switch (controller.status.value) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.failure:
              return ErrorView(
                message: controller.errorMessage.value ?? 'Chargement impossible.',
                onRetry: controller.load,
              );
            case LoadStatus.loaded:
              final count = itemCount();
              return RefreshIndicator(
                color: AppColors.green,
                onRefresh: controller.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  children: [
                    Text(title, style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle(), style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.lg),
                    if (count == 0)
                      SizedBox(
                        height: 320,
                        child: EmptyView(label: emptyLabel, hint: emptyHint, icon: emptyIcon),
                      )
                    else
                      for (var i = 0; i < count; i++) ...[
                        itemBuilder(context, i),
                        const SizedBox(height: AppSpacing.md),
                      ],
                  ],
                ),
              );
          }
        }),
      ),
      bottomNavigationBar: AdminNav(currentIndex: navIndex, controller: controller),
    );
  }
}
