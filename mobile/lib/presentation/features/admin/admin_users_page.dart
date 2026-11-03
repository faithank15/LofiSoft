import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/models/enums.dart';
import '../../components/atoms/status_text.dart';
import '../../components/molecules/admin_action_card.dart';
import 'admin_controller.dart';
import 'admin_dialogs.dart';
import 'admin_shell.dart';

/// Gestion des comptes : suspendre ou réactiver un utilisateur.
class AdminUsersPage extends GetView<AdminController> {
  const AdminUsersPage({super.key});

  static String _roleLabel(UserRole role) => switch (role) {
        UserRole.OWNER => 'Propriétaire',
        UserRole.ADMIN => 'Administrateur',
        UserRole.TENANT => 'Locataire',
      };

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      controller: controller,
      navIndex: 2,
      title: 'Utilisateurs',
      subtitle: () {
        final n = controller.users.length;
        return n == 1 ? '1 compte' : '$n comptes';
      },
      itemCount: () => controller.users.length,
      emptyLabel: 'Aucun compte',
      emptyHint: 'Les comptes créés sur la plateforme apparaîtront ici.',
      emptyIcon: Icons.group_outlined,
      itemBuilder: (context, index) {
        final user = controller.users[index];
        final locked = controller.isBusy(user.id);
        // Un administrateur ne se suspend pas lui-même : le serveur le refuse aussi.
        final canToggle = user.role != UserRole.ADMIN;
        return AdminActionCard(
          tagLabel: user.actif ? _roleLabel(user.role) : '${_roleLabel(user.role)} · suspendu',
          tagKind: user.actif ? StatusKind.neutral : StatusKind.bad,
          title: user.fullName,
          subtitle: user.identityVerified ? '${user.email} · identité vérifiée' : user.email,
          primaryLabel: canToggle && !user.actif ? 'Réactiver' : null,
          onPrimary: locked ? null : () => controller.setUserActive(user, actif: true),
          dangerLabel: canToggle && user.actif ? 'Suspendre' : null,
          onDanger: locked
              ? null
              : () async {
                  if (await confirmSuspension(context, user.fullName)) {
                    await controller.setUserActive(user, actif: false);
                  }
                },
        );
      },
    );
  }
}
