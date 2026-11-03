import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/atoms/app_avatar.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/molecules/info_row.dart';
import 'profile_controller.dart';

/// Profil : identité du compte et déconnexion.
class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Obx(() {
          final user = controller.user.value;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              const Align(alignment: Alignment.centerLeft, child: AppBackButton()),
              const SizedBox(height: AppSpacing.lg),
              Center(child: AppAvatar(initials: user?.initials ?? '?', size: 88, fontSize: 30)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                user == null || user.fullName.isEmpty ? 'Mon compte' : user.fullName,
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(controller.roleLabel, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.xl),
              if (user != null)
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      InfoRow(label: 'E-mail', value: user.email),
                      InfoRow(label: 'Téléphone', value: user.telephone, showDivider: false),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Se déconnecter',
                variant: AppButtonVariant.outline,
                isLoading: controller.isLoggingOut.value,
                onPressed: () => _confirmLogout(context),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    // Pris avant l'attente : si la page est quittée pendant la boîte de dialogue,
    // GetX supprime le contrôleur et un Get.find tardif lèverait « not found ».
    final profile = controller;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Se déconnecter ?', style: AppTextStyles.section),
        content: Text('Vous devrez vous reconnecter pour revenir.', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler', style: AppTextStyles.status.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Se déconnecter', style: AppTextStyles.status.copyWith(color: AppColors.statusBad)),
          ),
        ],
      ),
    );
    if (yes == true) await profile.logout();
  }
}
