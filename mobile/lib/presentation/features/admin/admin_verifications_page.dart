import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/date_format.dart';
import '../../components/molecules/admin_action_card.dart';
import '../../components/molecules/id_preview.dart';
import 'admin_controller.dart';
import 'admin_dialogs.dart';
import 'admin_shell.dart';

/// D2 : demandes de badge « Vérifié » des propriétaires.
class AdminVerificationsPage extends GetView<AdminController> {
  const AdminVerificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      controller: controller,
      navIndex: 1,
      title: 'Vérifications',
      subtitle: () {
        final n = controller.requests.length;
        return switch (n) {
          0 => 'Aucune demande en attente',
          1 => '1 propriétaire attend le badge Vérifié',
          _ => '$n propriétaires attendent le badge Vérifié',
        };
      },
      itemCount: () => controller.requests.length,
      emptyLabel: 'Aucune demande',
      emptyHint: 'Les pièces d’identité envoyées par les propriétaires apparaîtront ici.',
      emptyIcon: Icons.verified_user_outlined,
      itemBuilder: (context, index) {
        final request = controller.requests[index];
        final locked = controller.isBusy(request.id);
        final when = request.createdAt;
        return AdminActionCard(
          title: request.ownerName,
          subtitle: when == null
              ? request.housingsLabel
              : 'Demande envoyée ${AppDateFormat.ago(when).toLowerCase()} · ${request.housingsLabel}',
          child: IdPreview(idImageUrl: request.idImageUrl, selfieUrl: request.selfieUrl),
          primaryLabel: 'Valider',
          onPrimary: locked ? null : () => controller.approve(request),
          dangerLabel: 'Refuser',
          onDanger: locked
              ? null
              : () async {
                  final reason = await askRejectReason(context, request.ownerName);
                  if (reason != null) await controller.reject(request, reason);
                },
        );
      },
    );
  }
}
