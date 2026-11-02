import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../molecules/auth_header.dart';

/// Page de base de la Connexion et de l'Inscription : bandeau vert profond en haut
/// (logo, titre, toits) et panneau « papier » aux coins arrondis qui remonte par-dessus.


/// AuthScaffold(
///   title: 'Connexion',
///   subtitle: 'Ravi de vous revoir.',
///   child: Column(children: [
///     AppTextField(label: 'Adresse e-mail', controller: _email),
///     ...
///   ]),
/// )


class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.headerHeight = 300,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Contenu du panneau (champs, boutons, liens).
  final Widget child;

  /// Hauteur minimale du bandeau : 300 pour Connexion, 190 pour Inscription.
  final double headerHeight;

  /// De combien le panneau remonte sur le bandeau.
  static const double _overlap = 26;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              AuthHeader(
                title: title,
                subtitle: subtitle,
                onBack: onBack,
                height: headerHeight,
              ),
              Transform.translate(
                offset: const Offset(0, -_overlap),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.panel),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl + 4,
                    AppSpacing.xl,
                    AppSpacing.xl + MediaQuery.of(context).padding.bottom,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
