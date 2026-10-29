import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/models/announcement_model.dart';
import '../../components/atoms/app_network_image.dart';
import '../../shared/error_view.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'listing_details_controller.dart';

/// Couleurs de la maquette A3.
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

/// Détail d'une annonce (route /listings/details/:id).
class ListingDetailsPage extends StatelessWidget {
  const ListingDetailsPage({super.key});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  void _soon(String message) {
    Get.snackbar('Bientôt', message, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ListingDetailsController>();
    return Obx(() {
      final item = controller.item.value;
      if (controller.status.value == LoadStatus.failure) {
        return Scaffold(
          backgroundColor: _C.cream,
          appBar: AppBar(backgroundColor: _C.cream, elevation: 0, foregroundColor: _C.ink),
          body: ErrorView(
            message: controller.errorMessage.value ?? 'Annonce introuvable.',
            onRetry: controller.load,
          ),
        );
      }
      if (item == null) {
        return Scaffold(
          backgroundColor: _C.cream,
          appBar: AppBar(backgroundColor: _C.cream, elevation: 0, foregroundColor: _C.ink),
          body: const LoadingView(),
        );
      }
      return _content(context, controller, item);
    });
  }

  Widget _content(BuildContext context, ListingDetailsController controller, AnnouncementModel item) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.cream,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  // Image
                  SizedBox(
                    height: 290,
                    width: double.infinity,
                    child: item.photos.isEmpty
                        ? Container(
                            color: _C.imageBg,
                            child: const Center(
                              child: Icon(Icons.apartment, size: 120, color: _C.green),
                            ),
                          )
                        : PageView.builder(
                            itemCount: item.photos.length,
                            onPageChanged: (i) => controller.photoIndex.value = i,
                            itemBuilder: (_, i) => AppNetworkImage(
                              url: item.photos[i],
                              width: MediaQuery.of(context).size.width,
                              height: 290,
                            ),
                          ),
                  ),
                  // Panneau d'infos
                  Padding(
                    padding: const EdgeInsets.only(top: 264),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      decoration: const BoxDecoration(
                        color: _C.cream,
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prix + titre
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${CurrencyFormatter.number(item.rent)} ',
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
                            style: const TextStyle(fontSize: 15, color: _C.grey),
                          ),

                          // Description
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

                          // Lieu
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
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
                                  onPressed: () =>
                                      _soon("L'itinéraire arrive bientôt."),
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

                          // Propriétaire
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
                                      Row(
                                        children: [
                                          if (item.verified) ...[
                                            const Text(
                                              'Vérifié',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: _C.verified,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Bouton retour
                  Positioned(
                    top: topInset + 14,
                    left: 14,
                    child: _RoundButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => Get.back(),
                    ),
                  ),
                  // Bouton favori
                  Positioned(
                    top: topInset + 14,
                    right: 14,
                    child: Obx(
                      () => _RoundButton(
                        icon: controller.isFavorite.value ? Icons.favorite : Icons.favorite_border,
                        color: controller.isFavorite.value ? const Color(0xFFC8553D) : _C.ink,
                        onTap: controller.toggleFavorite,
                      ),
                    ),
                  ),
                  // Compteur de photos
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
                      child: Obx(() => Text(
                        '${controller.photoIndex.value + 1} / ${item.photos.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barre d'actions fixe
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
                      onPressed: () => _soon("L'appel arrive bientôt."),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text(
                        'Appeler',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
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
                      onPressed: () => _soon('WhatsApp arrive bientôt.'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
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

/// Bouton rond blanc (retour, favori).
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