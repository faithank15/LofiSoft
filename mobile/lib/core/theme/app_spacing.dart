/// Grille d'espacement : on n'invente pas de valeurs, on prend dans cette liste.
///
/// Usage : `SizedBox(height: AppSpacing.md)` ou `EdgeInsets.all(AppSpacing.lg)`
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  /// Marge gauche/droite standard de TOUS les écrans.
  static const double screen = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Hauteurs fixes des éléments standards (zones tactiles confortables, >= 44).
abstract final class AppSizes {
  /// Bouton principal.
  static const double button = 58;

  /// Petit bouton (dans une carte).
  static const double buttonSmall = 48;

  /// Champ de saisie.
  static const double field = 54;

  /// Barre du haut (AppBar personnalisée).
  static const double appBar = 60;

  /// Barre de navigation du bas.
  static const double bottomNav = 76;

  /// Taille minimale de toute zone cliquable.
  static const double tap = 44;
}
