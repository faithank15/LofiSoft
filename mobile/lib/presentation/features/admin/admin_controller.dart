import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/repo/admin_repository.dart';
import '../../../domain/models/admin_model.dart';
import '../../../domain/models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';

/// Contrôleur de l'administrateur : signalements (D1) et vérifications d'identité (D2).
class AdminController extends GetxController {
  AdminController({required AdminRepository repository}) : _repository = repository;

  final AdminRepository _repository;

  final Rx<LoadStatus> status = LoadStatus.initial.obs;
  final RxnString errorMessage = RxnString();

  final RxList<ReportItem> reports = <ReportItem>[].obs;
  final RxList<IdentityRequestItem> requests = <IdentityRequestItem>[].obs;
  final RxList<UserModel> users = <UserModel>[].obs;

  /// Identifiants (annonce ou demande) dont une action est en cours : leurs boutons sont bloqués.
  final RxSet<String> busy = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Charge les signalements et les demandes d'identité en attente.
  Future<void> load() async {
    status.value = LoadStatus.loading;
    errorMessage.value = null;
    try {
      final r = await _repository.reports();
      final i = await _repository.identityRequests();
      final u = await _repository.users();
      reports.assignAll(r);
      requests.assignAll(i);
      users.assignAll(u);
      status.value = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      status.value = LoadStatus.failure;
    } catch (_) {
      errorMessage.value = "Impossible de charger l'espace administrateur.";
      status.value = LoadStatus.failure;
    }
  }

  /// Une carte par annonce signalée.
  List<ReportGroup> get groups => ReportGroup.from(reports);

  bool isBusy(String id) => busy.contains(id);

  // ------------------------------------------------------------------ D1

  /// Supprime l'annonce : tous ses signalements sont clos, sinon la carte reviendrait.
  Future<void> removeAnnouncement(ReportGroup group) =>
      _treatGroup(group, _repository.removeAnnouncement, 'Annonce supprimée');

  /// Ignore tous les signalements de l'annonce.
  Future<void> dismiss(ReportGroup group) =>
      _treatGroup(group, _repository.dismissReport, 'Signalement ignoré');

  Future<void> _treatGroup(
    ReportGroup group,
    Future<String> Function(String reportId) action,
    String title,
  ) async {
    final key = group.announcementId;
    if (busy.contains(key)) return;
    busy.add(key);
    try {
      for (final report in group.reports) {
        await action(report.id);
        // Retiré dès que le serveur confirme : en cas d'échec au milieu, le reste reste visible.
        reports.removeWhere((r) => r.id == report.id);
      }
      _notify(title, group.headline);
    } on AppException catch (e) {
      _notify('Erreur', e.message);
    } catch (_) {
      _notify('Erreur', "L'action a échoué.");
    } finally {
      busy.remove(key);
    }
  }

  // ------------------------------------------------------------------ D2

  Future<void> approve(IdentityRequestItem request) => _treatRequest(
        request,
        () => _repository.approveIdentity(request.id),
        'Propriétaire vérifié',
      );

  Future<void> reject(IdentityRequestItem request, String reason) {
    final clean = reason.trim();
    if (clean.isEmpty) {
      _notify('Motif requis', 'Indiquez pourquoi la demande est refusée.');
      return Future.value();
    }
    return _treatRequest(
      request,
      () => _repository.rejectIdentity(request.id, reason: clean),
      'Demande refusée',
    );
  }

  Future<void> _treatRequest(
    IdentityRequestItem request,
    Future<String> Function() action,
    String title,
  ) async {
    if (busy.contains(request.id)) return;
    busy.add(request.id);
    try {
      await action();
      requests.removeWhere((r) => r.id == request.id);
      _notify(title, request.ownerName);
    } on AppException catch (e) {
      _notify('Erreur', e.message);
    } catch (_) {
      _notify('Erreur', "L'action a échoué.");
    } finally {
      busy.remove(request.id);
    }
  }

  // ------------------------------------------------------------ Utilisateurs

  /// Suspend ou réactive un compte ; la ligne est mise à jour dès que le serveur confirme.
  Future<void> setUserActive(UserModel user, {required bool actif}) async {
    if (busy.contains(user.id)) return;
    busy.add(user.id);
    try {
      await _repository.setUserActive(user.id, actif: actif);
      final index = users.indexWhere((u) => u.id == user.id);
      if (index >= 0) {
        users[index] = UserModel(
          id: user.id,
          nom: user.nom,
          prenoms: user.prenoms,
          email: user.email,
          telephone: user.telephone,
          role: user.role,
          actif: actif,
          identityVerified: user.identityVerified,
        );
      }
      _notify(actif ? 'Compte réactivé' : 'Compte suspendu', user.fullName);
    } on AppException catch (e) {
      _notify('Erreur', e.message);
    } catch (_) {
      _notify('Erreur', "L'action a échoué.");
    } finally {
      busy.remove(user.id);
    }
  }

  // ------------------------------------------------------------ Navigation

  /// Onglets du bas : 0 Signalements, 1 Vérifications, 2 Utilisateurs, 3 Profil.
  void goToTab(int index) {
    switch (index) {
      case 0:
        _open(AppRoutes.adminReports);
      case 1:
        _open(AppRoutes.adminVerifications);
      case 2:
        _open(AppRoutes.adminUsers);
      case 3:
        Get.toNamed(AppRoutes.profile);
    }
  }

  /// Ouvre l'annonce signalée (écran A3).
  void viewAnnouncement(ReportGroup group) =>
      Get.toNamed(AppRoutes.listingDetails.replaceFirst(':id', group.announcementId));

  void _open(String route) {
    if (Get.currentRoute != route) Get.offNamed(route);
  }

  void _notify(String title, String message) =>
      Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
}
