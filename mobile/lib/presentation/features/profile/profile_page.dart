import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/enums.dart';
import '../../components/atoms/app_avatar.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/molecules/info_row.dart';
import '../../routes/app_routes.dart';
import 'profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Obx(() {
          final user = controller.user.value;
          final isOwner = user?.role == UserRole.OWNER;
          final isAdmin = user?.role == UserRole.ADMIN;
          final isVerified = user?.identityVerified ?? false;

          return RefreshIndicator(
            color: AppColors.green,
            onRefresh: controller.reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton(),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Carte d'identité principale stylisée
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.panel),
                    border: Border.all(color: AppColors.line),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          AppAvatar(
                            initials: user?.initials ?? '?',
                            size: 92,
                            fontSize: 32,
                            variant: AppAvatarVariant.mint,
                          ),
                          if (isOwner && isVerified)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.statusOk,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                size: 20,
                                color: AppColors.surface,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        user == null || user.fullName.isEmpty
                            ? 'Mon compte'
                            : user.fullName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          controller.roleLabel,
                          style: AppTextStyles.status.copyWith(
                            color: AppColors.greenDeep,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Bannière vérification propriétaire si non certifié
                if (isOwner && !isVerified) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: const Color(0xFFFDBA74)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 32,
                          color: AppColors.statusWarn,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Identité non vérifiée',
                                style: AppTextStyles.bodyStrong.copyWith(
                                  fontSize: 15,
                                  color: AppColors.statusWarn,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Faites certifier votre compte pour inspirer confiance aux locataires.',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        TextButton(
                          onPressed: () =>
                              Get.toNamed(AppRoutes.onboardingProprietaire),
                          child: Text(
                            'Certifier',
                            style: AppTextStyles.status.copyWith(
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Section coordonnées
                Text('Coordonnées', style: AppTextStyles.section),
                const SizedBox(height: AppSpacing.sm),
                if (user != null)
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        InfoRow(
                          label: 'Adresse e-mail',
                          value: user.email,
                          showDivider: true,
                        ),
                        InfoRow(
                          label: 'Téléphone',
                          value: user.telephone.replaceFirst('+229', ''),
                          showDivider: isOwner || isAdmin,
                        ),
                        if (isOwner)
                          InfoRow(
                            label: 'Statut du profil',
                            value: isVerified
                                ? 'Certifié Vérifié'
                                : 'En attente',
                            showDivider: false,
                          ),
                        if (isAdmin)
                          InfoRow(
                            label: 'Rôle d’accès',
                            value: 'Administration plateforme',
                            showDivider: false,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),

                // Actions rapides selon le rôle
                Text('Accès rapide', style: AppTextStyles.section),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (!isOwner && !isAdmin)
                        _SettingsTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Mon suivi de loyer',
                          onTap: () => Get.offNamed(AppRoutes.rentTracking),
                        ),
                      if (isOwner)
                        _SettingsTile(
                          icon: Icons.apartment_outlined,
                          title: 'Gérer mes logements',
                          onTap: () => Get.offNamed(AppRoutes.ownerProperties),
                        ),
                      if (isAdmin)
                        _SettingsTile(
                          icon: Icons.flag_outlined,
                          title: 'Panneau de signalements',
                          onTap: () => Get.offNamed(AppRoutes.adminReports),
                        ),
                      _SettingsTile(
                        icon: Icons.lock_reset_rounded,
                        title: 'Réinitialiser mon mot de passe',
                        onTap: () => Get.toNamed(AppRoutes.forgotPassword),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Bouton de déconnexion moderne
                AppButton(
                  label: 'Se déconnecter',
                  variant: AppButtonVariant.outline,
                  isLoading: controller.isLoggingOut.value,
                  onPressed: () => _confirmLogout(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'LofiSoft v1.0.0 · Plateforme Immobilière Bénin',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final profile = controller;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text('Se déconnecter ?', style: AppTextStyles.section),
        content: Text(
          'Votre session active sera fermée sur cet appareil.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: AppTextStyles.status.copyWith(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Se déconnecter',
              style: AppTextStyles.status.copyWith(color: AppColors.statusBad),
            ),
          ),
        ],
      ),
    );
    if (yes == true) await profile.logout();
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.green, size: 22),
          title: Text(
            title,
            style: AppTextStyles.bodyStrong.copyWith(fontSize: 15),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
            size: 20,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 2,
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: AppColors.line),
      ],
    );
  }
}
