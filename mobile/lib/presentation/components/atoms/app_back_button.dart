import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Atome officiel LofiSoft de retour arrière.
///
/// Garantit une surface tactile minimale de 44x44 (conforme à [AppSizes.tap])
/// et s'adapte aux fonds clairs ou sombres.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.isLight = false,
    this.color,
  });

  /// Action déclenchée. Par défaut : [Get.back].
  final VoidCallback? onPressed;

  /// Si vrai, applique la couleur blanche pour les fonds vert foncé.
  final bool isLight;

  /// Couleur personnalisée explicite (prioritaire sur [isLight]).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? (isLight ? AppColors.surface : AppColors.ink);

    return SizedBox(
      width: AppSizes.tap,
      height: AppSizes.tap,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 22,
        onPressed: onPressed ?? () => Get.back(),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: effectiveColor,
        ),
        tooltip: 'Retour',
      ),
    );
  }
}
