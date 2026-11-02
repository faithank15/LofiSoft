import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/models/property_model.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/molecules/housing_code_box.dart';
import '../../components/molecules/selection_chip.dart';
import 'property_controller.dart';

/// Écran C6 : Ajouter un locataire (maquette C6-Ajouter-locataire.html).
/// Réécriture modulaire et responsive sans aucune altération des composants partagés.
class PropertyFormPage extends StatefulWidget {
  const PropertyFormPage({super.key});

  @override
  State<PropertyFormPage> createState() => _PropertyFormPageState();
}

class _PropertyFormPageState extends State<PropertyFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _rentController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _cautionController = TextEditingController();
  final _startDateController = TextEditingController();

  /// Rythme de paiement sélectionné (0: Chaque mois, 1: Autre rythme)
  int _paymentRhythm = 0;

  final PropertyController controller = Get.find<PropertyController>();

  @override
  void initState() {
    super.initState();
    _syncFieldsWithHousing(controller.selectedHousingForTenant.value);
  }

  @override
  void dispose() {
    _rentController.dispose();
    _dueDayController.dispose();
    _cautionController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  void _syncFieldsWithHousing(HousingModel? housing) {
    if (housing != null) {
      _rentController.text = housing.rent.toString();
      _dueDayController.text = 'le ${housing.dueDay}';
      _cautionController.text = (housing.rent * 2).toString();
      _startDateController.text = '01/03/2026';
    } else {
      _rentController.text = '350 000';
      _dueDayController.text = 'le 5';
      _cautionController.text = '700 000';
      _startDateController.text = '01/03/2026';
    }
  }

  void _onHousingSelected(HousingModel housing) {
    controller.selectHousingForTenant(housing);
    setState(() {
      _syncFieldsWithHousing(housing);
    });
  }

  /// Ouvre la modale de sélection de logement, bornée et scrollable pour éviter tout overflow.
  void _openHousingModalPicker() {
    if (controller.housings.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.panel),
        ),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.70,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sélectionner le logement',
                        style: AppTextStyles.title.copyWith(fontSize: 20),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: AppSizes.tap,
                          minHeight: AppSizes.tap,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.muted,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: controller.housings.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final h = controller.housings[index];
                        final isCurrent =
                            h.id ==
                            controller.selectedHousingForTenant.value?.id;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.field,
                            ),
                          ),
                          tileColor: isCurrent
                              ? AppColors.mint
                              : AppColors.surface,
                          title: Text(h.title, style: AppTextStyles.bodyStrong),
                          subtitle: Text(
                            h.location,
                            style: AppTextStyles.caption,
                          ),
                          trailing: isCurrent
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.green,
                                )
                              : null,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _onHousingSelected(h);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _shareCode(String code) {
    Share.share(
      'Votre propriétaire vous a attribué votre logement sur LofiSoft. Entrez ce code pour le rejoindre : $code',
      subject: 'Code logement LofiSoft',
    );
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final housing = controller.selectedHousingForTenant.value;
    if (housing == null) return;

    final cleanRent =
        int.tryParse(_rentController.text.replaceAll(RegExp(r'\s+'), '')) ??
        housing.rent;

    final cleanDueDay =
        int.tryParse(
          _dueDayController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        housing.dueDay;

    await controller.saveTenantLeaseConfig(
      housingId: housing.id,
      rent: cleanRent,
      dueDay: cleanDueDay,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barre d'en-tête (60 px : AppSizes.appBar)
            SizedBox(
              height: AppSizes.appBar,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Ajouter un locataire',
                        style: AppTextStyles.section,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Formulaire défilant responsive
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Champ sélecteur modulaire Logement avec chevron bas
                      Obx(() {
                        final housing =
                            controller.selectedHousingForTenant.value;
                        final name = housing != null
                            ? '${housing.title} · ${housing.location}'
                            : 'Appartement 2B · Résidence Le Soleil';

                        return _HousingSelectorField(
                          label: 'Logement',
                          value: name,
                          onTap: _openHousingModalPicker,
                        );
                      }),
                      const SizedBox(height: AppSpacing.lg),

                      // 2. Loyer par mois et Date d'échéance (LayoutBuilder responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 340;

                          final rentField = AppTextField(
                            label: 'Loyer par mois',
                            controller: _rentController,
                            suffixText: AppConstants.currency,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: Validators.requiredField,
                          );

                          final dueField = AppTextField(
                            label: 'À payer avant le',
                            controller: _dueDayController,
                            validator: Validators.requiredField,
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                rentField,
                                const SizedBox(height: AppSpacing.md),
                                dueField,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 13, child: rentField),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(flex: 10, child: dueField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 3. Paiement : pastilles Wrap anti-overflow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paiement', style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              SelectionChip(
                                label: 'Chaque mois',
                                selected: _paymentRhythm == 0,
                                onTap: () => setState(() => _paymentRhythm = 0),
                              ),
                              SelectionChip(
                                label: 'Autre rythme',
                                selected: _paymentRhythm == 1,
                                onTap: () => setState(() => _paymentRhythm = 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 4. Caution versée et Début du bail (LayoutBuilder responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 340;

                          final cautionField = AppTextField(
                            label: 'Caution versée',
                            controller: _cautionController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          );

                          final startField = AppTextField(
                            label: 'Début du bail',
                            controller: _startDateController,
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                cautionField,
                                const SizedBox(height: AppSpacing.md),
                                startField,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cautionField),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: startField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 5. Boîte : Code à donner au locataire (HousingCodeBox existant non altéré)
                      Obx(() {
                        final currentHousing =
                            controller.selectedHousingForTenant.value;
                        final activeCode = currentHousing?.code ?? 'M4T-83P';

                        return HousingCodeBox(
                          label: 'Code à donner au locataire',
                          code: activeCode,
                          helper:
                              'Le locataire crée son compte, puis entre ce code.',
                          onShare: () => _shareCode(activeCode),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // 6. Pied d'action fixe avec AppButton
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.line)),
                boxShadow: AppShadows.up,
              ),
              child: SafeArea(
                top: false,
                child: Obx(
                  () => AppButton(
                    label: 'Enregistrer',
                    isLoading: controller.isSubmitting.value,
                    onPressed: _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sélecteur modulaire du logement respectant la hauteur AppSizes.field (54 px)
/// et les tokens du thème sans modifier les composants partagés.
class _HousingSelectorField extends StatelessWidget {
  const _HousingSelectorField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.field),
          child: Container(
            height: AppSizes.field,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: AppColors.line, width: 1.5),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
