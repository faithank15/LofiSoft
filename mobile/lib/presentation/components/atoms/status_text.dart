import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Famille de couleur d'un statut.
enum StatusKind {
  /// Vert : Payé, Loué, Vérifié.
  ok,

  /// Brun : Partiel.
  warn,

  /// Rouge : En retard.
  bad,

  /// Gris : Libre, neutre.
  neutral,
}

/// Statut en TEXTE coloré, sans fond ni pastille (choix de la direction artistique).
///
/// ```dart
/// StatusText('Payé', kind: StatusKind.ok)
/// StatusText('En retard', kind: StatusKind.bad)
/// ```
class StatusText extends StatelessWidget {
  const StatusText(this.label, {super.key, this.kind = StatusKind.neutral});

  final String label;
  final StatusKind kind;

  /// Couleur d'un statut, utile pour d'autres composants.
  static Color colorOf(StatusKind kind) => switch (kind) {
        StatusKind.ok => AppColors.statusOk,
        StatusKind.warn => AppColors.statusWarn,
        StatusKind.bad => AppColors.statusBad,
        StatusKind.neutral => AppColors.muted,
      };

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      softWrap: false,
      style: AppTextStyles.status.copyWith(color: colorOf(kind)),
    );
  }
}
