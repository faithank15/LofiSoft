import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/cache/app_storage.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../data/repo/announcement_repository.dart';
import '../../../domain/models/announcement_model.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/search_preferences.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';

/// Fil d'annonces (A1) et favoris (A4).
///
/// Le fil applique par défaut les critères choisis à l'onboarding (ville, budget, type),
/// sauf si le visiteur demande « Voir tous les logements ».
class ListingsController extends GetxController {
  ListingsController({
    required AnnouncementRepository repository,
    required AuthStorage authStorage,
    required AppStorage appStorage,
  })  : _repository = repository,
        _auth = authStorage,
        _app = appStorage;

  final AnnouncementRepository _repository;
  final AuthStorage _auth;
  final AppStorage _app;

  // ---- Fil ----------------------------------------------------------------
  final items = <AnnouncementModel>[].obs;
  final status = LoadStatus.initial.obs;
  final errorMessage = RxnString();
  final hasMore = false.obs;
  final loadingMore = false.obs;

  /// Texte de la barre de recherche (ville ou quartier).
  final query = ''.obs;

  /// `true` : les critères de l'onboarding filtrent le fil.
  final usePreferences = true.obs;

  late final Rx<SearchPreferences> preferences = _app.preferences.obs;

  int _page = 1;

  // ---- Favoris -------------------------------------------------------------
  final favorites = <AnnouncementModel>[].obs;
  final favoritesStatus = LoadStatus.initial.obs;
  final favoriteIds = <String>{}.obs;

  bool get hasSession => _auth.hasSession;

  bool get _isTenant => _auth.hasSession && _auth.role == UserRole.TENANT;

  /// Critères réellement appliqués en ce moment.
  SearchPreferences get activePreferences =>
      usePreferences.value ? preferences.value : const SearchPreferences();

  @override
  void onInit() {
    super.onInit();
    loadFeed();
  }

  Future<void> loadFeed() async {
    status.value = LoadStatus.loading;
    errorMessage.value = null;
    _page = 1;
    try {
      final page = await _fetch(1);
      items.assignAll(page.items);
      hasMore.value = page.hasMore;
      _syncFavoriteIds(page.items);
      status.value = LoadStatus.loaded;
    } on AppException catch (e) {
      _failFeed(e.message);
    } catch (_) {
      _failFeed('Une erreur inattendue est survenue.');
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || loadingMore.value || status.value != LoadStatus.loaded) return;
    loadingMore.value = true;
    try {
      final page = await _fetch(_page + 1);
      _page += 1;
      items.addAll(page.items);
      hasMore.value = page.hasMore;
      _syncFavoriteIds(page.items);
    } on AppException {
      // On garde ce qui est affiché ; l'utilisateur peut refaire défiler.
    } finally {
      loadingMore.value = false;
    }
  }

  Future<AnnouncementPage> _fetch(int page) {
    final prefs = activePreferences;
    return _repository.list(
      city: prefs.city,
      type: prefs.apiType,
      minPrice: prefs.minPrice,
      maxPrice: prefs.maxPrice,
      q: query.value.trim(),
      page: page,
    );
  }

  void _failFeed(String message) {
    errorMessage.value = message;
    status.value = LoadStatus.failure;
  }

  void search(String text) {
    query.value = text;
    loadFeed();
  }

  /// « Voir tous les logements » : retire les critères de l'onboarding.
  void showAll() {
    usePreferences.value = false;
    loadFeed();
  }

  void editPreferences() => Get.toNamed(AppRoutes.onboardingVille);

  // ---- Favoris -------------------------------------------------------------
  Future<void> loadFavorites() async {
    if (!_isTenant) {
      favorites.clear();
      favoritesStatus.value = LoadStatus.loaded;
      return;
    }
    favoritesStatus.value = LoadStatus.loading;
    try {
      final list = await _repository.favorites();
      favorites.assignAll(list);
      favoriteIds
        ..clear()
        ..addAll(list.map((a) => a.id));
      favoritesStatus.value = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      favoritesStatus.value = LoadStatus.failure;
    }
  }

  bool isFavorite(String id) => favoriteIds.contains(id);

  /// Ajoute ou retire un favori. Réservé au locataire connecté.
  Future<void> toggleFavorite(AnnouncementModel item) async {
    if (!_isTenant) {
      Get.snackbar(
        'Connexion requise',
        'Connectez-vous avec un compte locataire pour enregistrer des logements.',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (!_auth.hasSession) Get.toNamed(AppRoutes.login);
      return;
    }
    final wanted = !isFavorite(item.id);
    _setLocalFavorite(item, wanted);
    try {
      await _repository.setFavorite(item.id, favorite: wanted);
    } on AppException catch (e) {
      _setLocalFavorite(item, !wanted);
      Get.snackbar('Erreur', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Appelé par la page de détail pour garder les listes à jour.
  void applyFavorite(AnnouncementModel item, bool value) => _setLocalFavorite(item, value);

  void _setLocalFavorite(AnnouncementModel item, bool value) {
    if (value) {
      favoriteIds.add(item.id);
      if (!favorites.any((a) => a.id == item.id)) favorites.add(item.copyWith(isFavorite: true));
    } else {
      favoriteIds.remove(item.id);
      favorites.removeWhere((a) => a.id == item.id);
    }
  }

  void _syncFavoriteIds(List<AnnouncementModel> list) {
    for (final a in list) {
      if (a.isFavorite) favoriteIds.add(a.id);
    }
  }

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
