import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum AppAvatarVariant {
  /// Fond menthe claire avec texte vert Lofi (style standard locataire/propriétaire).
  mint,

  /// Fond vert Lofi profond avec texte blanc (style mise en avant).
  solid,
}

/// Pastille circulaire affichant les initiales d'un utilisateur.
///
/// Extrait automatiquement jusqu'à 2 initiales majuscules depuis le nom fourni.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.name,
    this.initials,
    this.size = 44.0,
    this.variant = AppAvatarVariant.mint,
    this.fontSize,
  });

  /// Nom complet de l'utilisateur (ex. "Koffi Mensah") : les initiales en sont déduites.
  final String? name;

  /// Initiales déjà calculées (ex. « PA »). Prioritaires sur [name].
  final String? initials;

  /// Diamètre de la pastille circulaire (>= 44 recommandé).
  final double size;

  /// Variante chromatique du badge.
  final AppAvatarVariant variant;

  /// Taille optionnelle de la police. Si nulle, calculée proportionnellement à [size].
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    assert(name != null || initials != null, 'AppAvatar : fournir name ou initials');
    final label = initials ?? _extractInitials(name ?? '');
    final backgroundColor = variant == AppAvatarVariant.mint
        ? AppColors.mint
        : AppColors.green;
    final textColor = variant == AppAvatarVariant.mint
        ? AppColors.green
        : AppColors.surface;

    final effectiveFontSize = fontSize ?? (size * 0.36);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(
          color: textColor,
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  static String _extractInitials(String rawName) {
    final cleaned = rawName.trim();
    if (cleaned.isEmpty) {
      return '';
    }

    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      final single = parts.first;
      return single.length >= 2
          ? single.substring(0, 2).toUpperCase()
          : single.substring(0, 1).toUpperCase();
    }

    final first = parts.first[0];
    final second = parts[1][0];
    return '$first$second'.toUpperCase();
  }
}
