/// Fonctions de validation des champs de saisie.
/// Toutes ont la forme `String? Function(String?)` : elles renvoient `null` si la valeur
/// est valide, sinon le message d'erreur à afficher. Directement utilisables dans
/// `AppTextField(validator: Validators.email)`.
///
/// (Ce fichier peut déjà exister chez un autre membre de l'équipe : garder une seule version.)
abstract final class Validators {
  /// Champ obligatoire.
  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ce champ est obligatoire.';
    return null;
  }

  /// Nom complet : au moins 2 caractères.
  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Entrez votre nom complet.';
    if (v.length < 2) return 'Ce nom est trop court.';
    return null;
  }

  /// Adresse e-mail valide.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Entrez votre adresse e-mail.';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(v);
    return ok ? null : 'Cette adresse e-mail n’est pas valide.';
  }

  /// Numéro béninois SANS l'indicatif +229 : 10 chiffres commençant par 01
  /// (format en vigueur depuis la réforme de 2024). Les espaces sont ignorés.
  /// À confirmer avec le cahier des charges si besoin d'accepter d'autres formats.
  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[\s.\-]'), '');
    if (digits.isEmpty) return 'Entrez votre numéro de téléphone.';
    if (!RegExp(r'^01\d{8}$').hasMatch(digits)) {
      return 'Numéro invalide : 10 chiffres, commençant par 01.';
    }
    return null;
  }

  /// Mot de passe : 8 caractères minimum, avec au moins une lettre et un chiffre.
  static String? strongPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Entrez un mot de passe.';
    if (v.length < 8) return 'Au moins 8 caractères.';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Mélangez des lettres et des chiffres.';
    }
    return null;
  }

  /// Mot de passe à la CONNEXION : seulement non vide (on ne juge pas sa force).
  static String? passwordPresent(String? value) {
    if (value == null || value.isEmpty) return 'Entrez votre mot de passe.';
    return null;
  }
}
