import 'package:get/get.dart';

import '../../routes/app_routes.dart';

/// Annonce simplifiée pour l'affichage.
/// À remplacer par le vrai modèle quand le backend sera prêt.
class ListingItem {
  const ListingItem({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    this.verified = false,
    this.features = const [],
    this.description = '',
    this.locationHint = '',
    this.ownerName = '',
    this.ownerRating,
    this.ownerReviews = 0,
  });

  final String id;
  final String title;
  final num price;
  final String location;
  final bool verified;
  final List<String> features;
  final String description;
  final String locationHint;
  final String ownerName;
  final double? ownerRating;
  final int ownerReviews;
}

class ListingsController extends GetxController {
  final items = <ListingItem>[
    const ListingItem(
      id: '1',
      title: 'Appartement · 3 pièces',
      price: 250000,
      location: 'Fidjrossè, Cotonou',
      verified: true,
    ),
    const ListingItem(
      id: '2',
      title: 'Maison · 4 pièces',
      price: 280000,
      location: 'Haie Vive, Cotonou',
    ),
    const ListingItem(
      id: '3',
      title: 'Appartement · 3 pièces · 85 m²',
      price: 350000,
      location: 'Fidjrossè, Cotonou',
      verified: true,
      features: ['Climatisation', 'Parking', 'Gardien 24 h'],
      description:
      "Appartement lumineux au 2e étage d'un immeuble sécurisé. Salon, deux chambres, cuisine équipée et balcon.",
      locationHint: 'À 400 m de la plage, près de la pharmacie Calvaire',
      ownerName: 'Koffi Mensah',
      ownerRating: 4.8,
      ownerReviews: 12,
    ),
    const ListingItem(
      id: '4',
      title: 'Studio · 1 pièce',
      price: 80000,
      location: 'Akpakpa, Cotonou',
    ),
    const ListingItem(
      id: '5',
      title: 'Maison · 4 pièces',
      price: 250000,
      location: 'Togoudo, Abomey-Calavi',
    ),
  ].obs;

  /// Trois favoris au départ, comme sur la maquette.
  final favoriteIds = <String>{'3', '4', '5'}.obs;

  bool isFavorite(String id) => favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (!favoriteIds.remove(id)) favoriteIds.add(id);
  }

  List<ListingItem> get favorites =>
      items.where((i) => favoriteIds.contains(i.id)).toList();

  ListingItem? byId(String id) =>
      items.firstWhereOrNull((i) => i.id == id);

  /// Navigation de la barre du bas.
  void goToTab(int index) {
    switch (index) {
      case 0:
        Get.offNamed(AppRoutes.listings);
      case 1:
        Get.offNamed(AppRoutes.favorites);
      case 2:
        Get.offNamed(AppRoutes.rentTracking);
    }
  }
}