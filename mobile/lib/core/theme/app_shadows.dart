import 'package:flutter/material.dart';

/// Ombres LofiSoft : toujours LÉGÈRES et floues. Jamais d'ombre dure ni colorée
/// (sauf celle du bouton principal, volontairement verte).
///
/// Usage : `BoxDecoration(boxShadow: AppShadows.soft)`
abstract final class AppShadows {
  /// Cartes et panneaux (AppCard, champs mis en avant).
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F10231E), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x2910231E),
      blurRadius: 26,
      spreadRadius: -8,
      offset: Offset(0, 10),
    ),
  ];

  /// Bouton principal (AppButton) : ombre verte douce.
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x990F5C4D),
      blurRadius: 20,
      spreadRadius: -8,
      offset: Offset(0, 10),
    ),
  ];

  /// Barres fixes en bas (BottomCtaBar, AppBottomNav) : ombre vers le HAUT.
  static const List<BoxShadow> up = [
    BoxShadow(
      color: Color(0x2910231E),
      blurRadius: 22,
      spreadRadius: -10,
      offset: Offset(0, -8),
    ),
  ];
}
