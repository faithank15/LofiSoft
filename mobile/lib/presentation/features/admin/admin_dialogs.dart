import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/molecules/app_bottom_nav.dart';
import 'admin_controller.dart';

/// Barre du bas de l'administrateur, commune aux deux écrans.
class AdminNav extends StatelessWidget {
  const AdminNav({super.key, required this.currentIndex, required this.controller});

  final int currentIndex;
  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return AppBottomNav(
      items: AppNavItems.admin,
      currentIndex: currentIndex,
      onTap: controller.goToTab,
    );
  }
}

/// Demande confirmation avant de supprimer une annonce. `true` si confirmé.
Future<bool> confirmRemoval(BuildContext context, String headline) => _confirm(
      context,
      title: 'Supprimer cette annonce ?',
      message: '« $headline » ne sera plus visible. Tous ses signalements seront clos.',
      confirmLabel: 'Supprimer',
      danger: true,
    );

/// Demande confirmation avant de suspendre un compte. `true` si confirmé.
Future<bool> confirmSuspension(BuildContext context, String name) => _confirm(
      context,
      title: 'Suspendre ce compte ?',
      message: '$name ne pourra plus se connecter tant que le compte n\u2019est pas réactivé.',
      confirmLabel: 'Suspendre',
      danger: true,
    );

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: AppTextStyles.section),
      content: Text(message, style: AppTextStyles.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Annuler', style: AppTextStyles.status.copyWith(color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            confirmLabel,
            style: AppTextStyles.status.copyWith(color: danger ? AppColors.statusBad : AppColors.green),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Demande le motif d'un refus d'identité. `null` si l'administrateur annule.
Future<String?> askRejectReason(BuildContext context, String ownerName) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RejectReasonDialog(ownerName: ownerName),
  );
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog({required this.ownerName});

  final String ownerName;

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _reason.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Indiquez le motif du refus.');
      return;
    }
    Get.back<String>(result: text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Refuser ${widget.ownerName} ?', style: AppTextStyles.section),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Le motif sera communiqué au propriétaire.', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _reason,
            hintText: 'Ex. : pièce illisible',
            errorText: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<String>(),
          child: Text('Annuler', style: AppTextStyles.status.copyWith(color: AppColors.muted)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text('Refuser', style: AppTextStyles.status.copyWith(color: AppColors.statusBad)),
        ),
      ],
    );
  }
}
