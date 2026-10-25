import 'package:flutter/material.dart';

/// Palette officielle LofiSoft (direction artistique v2, celle des maquettes).
///
/// RÈGLE : ne jamais écrire `Color(0xFF...)` ni `Colors.xxx` dans une page ou un
/// composant. On prend toujours une couleur d'ici.
/// Pour une transparence : `AppColors.ink.withValues(alpha: 0.5)` (jamais withOpacity).
abstract final class AppColors {
  // ---- Fonds et textes --------------------------------------------------
  /// Fond de TOUS les écrans (beige très clair).
  static const paper = Color(0xFFF7F3EA);

  /// Blanc : cartes, champs de saisie, barres du bas.
  static const surface = Color(0xFFFFFFFF);

  /// Texte principal (vert très sombre, jamais du noir pur).
  static const ink = Color(0xFF10231E);

  /// Texte secondaire : sous-titres, légendes, libellés discrets.
  static const muted = Color(0xFF55645E);

  /// Traits fins : bordures de cartes et de champs, séparateurs.
  static const line = Color(0xFFE1DACB);

  // ---- Marque -----------------------------------------------------------
  /// Vert Lofi : boutons principaux, liens, éléments actifs.
  static const green = Color(0xFF0F5C4D);

  /// Vert profond : bandeaux, écran de lancement, en-têtes sombres.
  static const greenDeep = Color(0xFF0A3D33);

  /// Menthe : pastille de l'onglet actif, avatar, fond doux.
  static const mint = Color(0xFFD6EBDD);

  /// Vert feuille : illustrations "payé".
  static const leaf = Color(0xFF2F8F6B);

  /// Ambre : accent à petite dose (logo, soleil). Jamais en grand aplat.
  static const amber = Color(0xFFF2B134);

  /// Sable : fonds d'illustrations.
  static const sand = Color(0xFFEBDFC6);

  /// Argile : cœur des favoris, "en retard" dans les illustrations.
  static const clay = Color(0xFFC75B39);

  // ---- Statuts (TEXTE coloré, jamais de fond teinté) ---------------------
  /// Payé, Loué, Vérifié.
  static const statusOk = Color(0xFF0B6B3A);

  /// Partiel.
  static const statusWarn = Color(0xFF7A4B00);

  /// En retard, Supprimer, Refuser, erreurs.
  static const statusBad = Color(0xFFA3262A);

  // ---- Remplissages d'illustrations (jauge, immeuble) --------------------
  static const fillPaid = Color(0xFF2F8F6B);
  static const fillPartial = Color(0xFFE0A526);
  static const fillLate = Color(0xFFC75B39);
  static const fillFree = Color(0xFFD3CCBA);
}
