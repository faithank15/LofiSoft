import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/models/announcement_model.dart';
import '../../../domain/models/report_model.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_network_image.dart';
import '../../components/atoms/app_text_field.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'listing_details_controller.dart';

class _C {
  static const ink = Color(0xFF10231E);
  static const green = Color(0xFF0F5C4D);
  static const mint = Color(0xFFD6EBDD);
  static const imageBg = Color(0xFFCFE5D8);
  static const cream = Color(0xFFF7F3EA);
  static const border = Color(0xFFE1DACB);
  static const grey = Color(0xFF55645E);
  static const verified = Color(0xFF0B6B3A);
}

class ListingDetailsPage extends StatelessWidget {
  const ListingDetailsPage({super.key});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _openMaps(String query) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Itinéraire',
        'Impossible d’ouvrir l’application de cartes.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showReportDialog(
    BuildContext context,
    ListingDetailsController controller,
  ) {
    String selectedReason = ReportRequest.commonReasons.first;
    final detailsController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.panel),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                MediaQuery.of(modalCtx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Signaler cette annonce',
                        style: AppTextStyles.title,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.muted,
                        ),
                        onPressed: () => Navigator.of(modalCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sélectionnez le motif principal correspondant à votre signalement.',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: ReportRequest.commonReasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        selectedColor: AppColors.green,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.surface : AppColors.ink,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: isSelected ? AppColors.green : AppColors.line,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => selectedReason = reason);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Précisions supplémentaires (facultatif)',
                    controller: detailsController,
                    maxLines: 3,
                    minLines: 2,
                    hintText: 'Expliquez en quelques mots ce qui ne va pas...',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Obx(
                    () => AppButton(
                      label: 'Envoyer le signalement',
                      isLoading: controller.isReporting.value,
                      onPressed: () async {
                        final ok = await controller.report(
                          reason: selectedReason,
                          details: detailsController.text,
                        );
                        if (ok && modalCtx.mounted) {
                          Navigator.of(modalCtx).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ListingDetailsController>();
    return Obx(() {
      final item = controller.item.value;
      if (controller.status.value == LoadStatus.failure) {
        return Scaffold(
          backgroundColor: _C.cream,
          appBar: AppBar(
            backgroundColor: _C.cream,
            elevation: 0,
            foregroundColor: _C.ink,
          ),
          body: ErrorView(
            message: controller.errorMessage.value ?? 'Annonce introuvable.',
            onRetry: controller.load,
          ),
        );
      }
      if (item == null) {
        return Scaffold(
          backgroundColor: _C.cream,
          appBar: AppBar(
            backgroundColor: _C.cream,
            elevation: 0,
            foregroundColor: _C.ink,
          ),
          body: const LoadingView(),
        );
      }
      return _content(context, controller, item);
    });
  }

  Widget _content(
    BuildContext context,
    ListingDetailsController controller,
    AnnouncementModel item,
  ) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.cream,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  SizedBox(
                    height: 290,
                    width: double.infinity,
                    child: item.photos.isEmpty
                        ? Container(
                            color: _C.imageBg,
                            child: const Center(
                              child: Icon(
                                Icons.apartment,
                                size: 120,
                                color: _C.green,
                              ),
                            ),
                          )
                        : PageView.builder(
                            itemCount: item.photos.length,
                            onPageChanged: (i) =>
                                controller.photoIndex.value = i,
                            itemBuilder: (ctx, i) => AppNetworkImage(
                              url: item.photos[i],
                              width: MediaQuery.of(context).size.width,
                              height: 290,
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 264),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      decoration: const BoxDecoration(
                        color: _C.cream,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${CurrencyFormatter.number(item.rent)} ',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: _C.ink,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'FCFA / mois',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _C.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _C.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.rooms} pièce${item.rooms > 1 ? 's' : ''}'
                            '${item.depositMonths > 0 ? ' · Caution : ${item.depositMonths} mois' : ''}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: _C.grey,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: _C.ink,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _C.border),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2910231E),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _C.mint,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    color: _C.green,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.location,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _C.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _openMaps(item.location),
                                  child: const Text(
                                    'Itinéraire',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _C.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.ownerName.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _C.green,
                                  child: Text(
                                    _initials(item.ownerName),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.ownerName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _C.ink,
                                        ),
                                      ),
                                      if (item.verified) ...[
                                        const Text(
                                          'Vérifié',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: _C.verified,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  _showReportDialog(context, controller),
                              icon: const Icon(
                                Icons.flag_outlined,
                                size: 18,
                                color: AppColors.statusBad,
                              ),
                              label: Text(
                                'Signaler cette annonce',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.statusBad,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: topInset + 14,
                    left: 14,
                    child: _RoundButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => Get.back(),
                    ),
                  ),
                  Positioned(
                    top: topInset + 14,
                    right: 14,
                    child: Obx(
                      () => _RoundButton(
                        icon: controller.isFavorite.value
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: controller.isFavorite.value
                            ? const Color(0xFFC8553D)
                            : _C.ink,
                        onTap: controller.toggleFavorite,
                      ),
                    ),
                  ),
                  if (item.photos.length > 1)
                    Positioned(
                      top: 216,
                      right: 14,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _C.ink,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Obx(
                          () => Text(
                            '${controller.photoIndex.value + 1} / ${item.photos.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _C.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.snackbar(
                          'Contact propriétaire',
                          'Entrez en contact avec ${item.ownerName.isNotEmpty ? item.ownerName : 'le propriétaire'} après visite.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: const Icon(Icons.call_outlined),
                      label: const Text(
                        'Appeler',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.snackbar(
                          'WhatsApp',
                          'Le canal WhatsApp propriétaire est en cours de déploiement.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.green,
                        side: const BorderSide(color: _C.green, width: 2),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.color = _C.ink,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}
