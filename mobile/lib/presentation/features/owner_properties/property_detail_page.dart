import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/domain/models/enums.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/models/property_model.dart';
import '../../components/atoms/app_avatar.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/molecules/housing_code_box.dart';
import '../../components/molecules/info_row.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'property_controller.dart';

/// Écran C5 : Détail d’un logement.
class PropertyDetailPage extends StatefulWidget {
  const PropertyDetailPage({super.key});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  final PropertyController controller = Get.find<PropertyController>();
  late final String housingId;

  @override
  void initState() {
    super.initState();
    housingId = Get.parameters['id'] ?? '';
    controller.loadDetail(housingId);
  }

  void _shareCode(String code, String title) {
    Share.share(
      'Rejoignez le logement "$title" sur LofiSoft en entrant ce code : $code',
      subject: 'Code logement LofiSoft',
    );
  }

  Future<void> _callTenant(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        'Appel indisponible',
        'Impossible de composer le numéro $phone.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _confirmEndRental(
    BuildContext context,
    String rentalId,
    String housingTitle,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text('Retirer ce locataire ?', style: AppTextStyles.title),
        content: Text(
          'Cette action mettra fin au bail en cours pour $housingTitle. Le logement redeviendra libre.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Annuler',
              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.muted),
            ),
          ),
          Obx(
            () => AppButton(
              label: 'Confirmer',
              expanded: false,
              isLoading: controller.isSubmitting.value,
              onPressed: () async {
                final success = await controller.endRental(
                  rentalId: rentalId,
                  housingId: housingId,
                );
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Obx(() {
        switch (controller.detailStatus.value) {
          case LoadStatus.initial:
          case LoadStatus.loading:
            return const Scaffold(
              backgroundColor: AppColors.paper,
              body: LoadingView(),
            );

          case LoadStatus.failure:
            return Scaffold(
              backgroundColor: AppColors.paper,
              appBar: AppBar(
                backgroundColor: AppColors.paper,
                elevation: 0,
                leading: const AppBackButton(),
              ),
              body: ErrorView(
                message:
                    controller.errorMessage.value ?? 'Logement introuvable.',
                onRetry: () => controller.loadDetail(housingId),
              ),
            );

          case LoadStatus.loaded:
            final housing = controller.selectedHousing.value;
            if (housing == null) {
              return const Scaffold(
                backgroundColor: AppColors.paper,
                body: Center(child: Text('Aucun détail disponible.')),
              );
            }
            return _buildHousingDetail(context, housing);
        }
      }),
    );
  }

  Widget _buildHousingDetail(BuildContext context, HousingModel housing) {
    final activeRental = housing.activeRental;
    final isRented = housing.isRented;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau haut vert profond
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              MediaQuery.of(context).padding.top + 8,
              AppSpacing.xl,
              26,
            ),
            decoration: const BoxDecoration(
              color: AppColors.greenDeep,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.panel),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppBackButton(isLight: true),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        housing.title,
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.surface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isRented
                            ? AppColors.statusOk.withValues(alpha: 0.25)
                            : AppColors.surface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        housing.statusLabel,
                        style: AppTextStyles.status.copyWith(
                          color: isRented
                              ? const Color(0xFFBFE8CF)
                              : AppColors.surface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        housing.location,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.mint.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: CurrencyFormatter.number(housing.rent),
                              style: AppTextStyles.amount.copyWith(
                                color: AppColors.surface,
                                fontSize: 36,
                              ),
                            ),
                            TextSpan(
                              text: ' FCFA / mois',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.mint,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fiche Locataire si le logement est occupé
                if (isRented && activeRental != null) ...[
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        AppAvatar(name: activeRental.tenantName),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Locataire', style: AppTextStyles.caption),
                              Text(
                                activeRental.tenantName,
                                style: AppTextStyles.bodyStrong.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                              if (activeRental.startedAt != null)
                                Text(
                                  'Depuis le ${activeRental.startedAt!.day.toString().padLeft(2, '0')}/${activeRental.startedAt!.month.toString().padLeft(2, '0')}/${activeRental.startedAt!.year}',
                                  style: AppTextStyles.caption,
                                ),
                            ],
                          ),
                        ),
                        if (activeRental.tenantPhone.isNotEmpty)
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () =>
                                  _callTenant(activeRental.tenantPhone),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.green,
                                side: const BorderSide(
                                  color: AppColors.green,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Icon(Icons.call_outlined, size: 22),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Conditions du logement
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'À payer avant le',
                        value: 'le ${housing.dueDay} de chaque mois',
                        showDivider: true,
                      ),
                      InfoRow(
                        label: 'Type de logement',
                        value: switch (housing.type) {
                          AccommodationType.HOUSE => 'Maison / Appartement',
                          AccommodationType.ROOM => 'Chambre / Studio',
                          AccommodationType.OTHER => 'Autre',
                        },
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Boîte Code logement avec partage
                HousingCodeBox(
                  code: housing.code,
                  helper: isRented
                      ? 'Code assigné à ce logement.'
                      : 'Donnez ce code à votre locataire pour qu’il rejoigne ce logement.',
                  onShare: () => _shareCode(housing.code, housing.title),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Actions d'administration du bail
                if (isRented && activeRental != null) ...[
                  AppButton(
                    label: 'Retirer ce locataire',
                    variant: AppButtonVariant.text,
                    onPressed: () => _confirmEndRental(
                      context,
                      activeRental.id,
                      housing.title,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
