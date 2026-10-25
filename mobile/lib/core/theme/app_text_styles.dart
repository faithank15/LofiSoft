import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Styles de texte LofiSoft, police Plus Jakarta Sans.
///
/// MISE EN PLACE (une seule fois, par la personne du thème) :
///  1. Télécharger Plus Jakarta Sans (graisses 400, 600, 700, 800) et mettre les
///     .ttf dans `assets/fonts/`.
///  2. Les déclarer dans pubspec.yaml sous `fonts:` avec `family: PlusJakartaSans`.
///
/// Usage : `Text('Bonjour', style: AppTextStyles.title)`
/// Pour changer seulement la couleur : `AppTextStyles.body.copyWith(color: AppColors.muted)`
abstract final class AppTextStyles {
  static const _family = 'PlusJakartaSans';

  static const _base = TextStyle(fontFamily: _family, color: AppColors.ink);

  /// Grand titre d'écran (ex. « Trouvez votre logement au Bénin »). 28 / 800.
  static final display = _base.copyWith(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.56,
  );

  /// Titre d'écran (ex. « Mes logements »). 24 / 800.
  static final title = _base.copyWith(
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  /// Titre de section (ex. « À suivre », « Annonces récentes »). 20 / 800.
  static final section = _base.copyWith(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w800,
  );

  /// Gros montant mis en avant (ex. « 60 000 FCFA » du loyer). 44 / 800.
  static final amount = _base.copyWith(
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.3,
  );

  /// Texte courant. 16 / 400.
  static final body = _base.copyWith(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// Texte courant en gras (nom d'un locataire, prix dans une carte). 16 / 800.
  static final bodyStrong = body.copyWith(fontWeight: FontWeight.w800);

  /// Libellé d'un champ de saisie. 15 / 800.
  static final label = _base.copyWith(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w800,
  );

  /// Sous-titre, texte secondaire (couleur adoucie). 15 / 400.
  static final subtitle = _base.copyWith(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );

  /// Texte du bouton principal. 17 / 800.
  static final button = _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.surface,
  );

  /// Texte de statut (Payé, Partiel...). 14 / 800. Ajouter la couleur du statut.
  static final status = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  /// Petite légende, détails (« 90 000 payés sur 150 000 »). 14 / 400.
  static final caption = _base.copyWith(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );

  /// Libellé de la barre de navigation. 13 / 700.
  static final nav = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
}
