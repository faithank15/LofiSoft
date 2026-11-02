import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/date_format.dart';
import '../../components/atoms/status_text.dart';
import '../../components/molecules/admin_action_card.dart';
import 'admin_controller.dart';
import 'admin_dialogs.dart';
import 'admin_shell.dart';

/// D1 : signalements d'annonces à traiter.
class AdminReportsPage extends GetView<AdminController> {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      controller: controller,
      navIndex: 0,
      title: 'Signalements',
      subtitle: () {
        final n = controller.groups.length;
        return n == 0 ? 'Rien à traiter' : '$n à traiter';
      },
      itemCount: () => controller.groups.length,
      emptyLabel: 'Aucun signalement',
      emptyHint: 'Les annonces signalées par les utilisateurs apparaîtront ici.',
      emptyIcon: Icons.flag_outlined,
      itemBuilder: (context, index) {
        final group = controller.groups[index];
        final locked = controller.isBusy(group.announcementId);
        final when = group.createdAt;
        return AdminActionCard(
          tagLabel: group.reason,
          tagKind: StatusKind.bad,
          meta: when == null ? null : AppDateFormat.ago(when),
          title: group.headline,
          subtitle: group.subtitle,
          primaryLabel: 'Voir',
          onPrimary: locked ? null : () => controller.viewAnnouncement(group),
          dangerLabel: 'Supprimer',
          onDanger: locked
              ? null
              : () async {
                  if (await confirmRemoval(context, group.headline)) {
                    await controller.removeAnnouncement(group);
                  }
                },
          tertiaryLabel: 'Ignorer',
          onTertiary: locked ? null : () => controller.dismiss(group),
        );
      },
    );
  }
}
