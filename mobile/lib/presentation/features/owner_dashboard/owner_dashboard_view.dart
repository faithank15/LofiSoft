import 'package:get/get.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/owner_dashboard_model.dart';
import '../../components/atoms/status_text.dart';

/// Texte et couleur d'un statut de loyer.
extension RentStatusView on RentStatus {
  String get label => switch (this) {
    RentStatus.PAID => 'Payé',
    RentStatus.PARTIAL => 'Partiel',
    RentStatus.LATE => 'En retard',
    RentStatus.UPCOMING => 'À venir',
  };

  StatusKind get kind => switch (this) {
    RentStatus.PAID => StatusKind.ok,
    RentStatus.PARTIAL => StatusKind.warn,
    RentStatus.LATE => StatusKind.bad,
    RentStatus.UPCOMING => StatusKind.neutral,
  };
}

/// Sous-titres d'une ligne de locataire.
extension TenantRentView on TenantRent {
  /// C1 : « Appart. 3C · 170 000 dus » ou « Appart. 1A · reste 60 000 »
  String get homeSubtitle {
    final left = remaining;
    final detail = status == RentStatus.PARTIAL && left != null
        ? 'reste ${CurrencyFormatter.number(left)}'
        : '${CurrencyFormatter.number(due)} dus';
    return '$shortHousing · $detail';
  }

  /// C7 : « Appartement 1A · 90 000 sur 150 000 »
  String get rentsSubtitle {
    final p = paid;
    final detail = p != null
        ? '${CurrencyFormatter.number(p)} sur ${CurrencyFormatter.number(due)}'
        : '${CurrencyFormatter.number(due)} dus';
    return '$housing · $detail';
  }
}

/// Message provisoire pour les boutons dont l'écran n'existe pas encore.
void showSoon(String message) {
  Get.snackbar('Bientôt', message, snackPosition: SnackPosition.BOTTOM);
}