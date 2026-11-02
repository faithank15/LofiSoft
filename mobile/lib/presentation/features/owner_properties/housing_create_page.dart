import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/models/enums.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/molecules/bottom_cta_bar.dart';
import '../../components/molecules/selection_chip.dart';
import '../../routes/app_routes.dart';
import 'property_controller.dart';

/// Nouveau logement (bouton « + Ajouter » de C2). Le logement reçoit son code à la création ;
/// c'est lui qui sert ensuite aux annonces et à l'ajout d'un locataire.
class HousingCreatePage extends StatefulWidget {
  const HousingCreatePage({super.key});

  @override
  State<HousingCreatePage> createState() => _HousingCreatePageState();
}

class _HousingCreatePageState extends State<HousingCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _rent = TextEditingController();
  final _dueDay = TextEditingController(text: '5');
  final _city = TextEditingController();
  final _district = TextEditingController();

  final controller = Get.find<PropertyController>();
  final _type = AccommodationType.HOUSE.obs;

  @override
  void dispose() {
    _title.dispose();
    _rent.dispose();
    _dueDay.dispose();
    _city.dispose();
    _district.dispose();
    super.dispose();
  }

  int _number(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  String? _rentError(String? v) {
    final n = int.tryParse((v ?? '').replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (n == 0) return 'Indiquez le loyer.';
    if (n < 1000) return 'Le loyer doit être d’au moins 1 000 FCFA.';
    return null;
  }

  String? _dueDayError(String? v) {
    final n = int.tryParse((v ?? '').trim()) ?? 0;
    return n < 1 || n > 28 ? 'Entre 1 et 28.' : null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final created = await controller.createHousing(
      title: _title.text,
      type: _type.value,
      rent: _number(_rent),
      dueDay: _number(_dueDay),
      city: _city.text,
      district: _district.text,
    );
    if (created == null) return;
    Get.snackbar('Logement ajouté', 'Son code : ${created.code}', snackPosition: SnackPosition.BOTTOM);
    // Le détail affiche le code à partager avec le locataire.
    Get.offNamed(AppRoutes.ownerPropertyDetail.replaceFirst(':id', created.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: AppSpacing.md),
                  Text('Nouveau logement', style: AppTextStyles.section),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: 'Nom du logement',
                        controller: _title,
                        hintText: 'Appartement 2B',
                        textInputAction: TextInputAction.next,
                        validator: Validators.requiredField,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Type', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      Obx(
                        () => Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final (t, label) in [
                              (AccommodationType.HOUSE, 'Maison'),
                              (AccommodationType.ROOM, 'Chambre'),
                              (AccommodationType.OTHER, 'Autre'),
                            ])
                              SelectionChip(label: label, selected: _type.value == t, onTap: () => _type.value = t),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Loyer par mois',
                        controller: _rent,
                        suffixText: 'FCFA',
                        hintText: '150000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textInputAction: TextInputAction.next,
                        validator: _rentError,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'À payer avant le (jour du mois)',
                        controller: _dueDay,
                        hintText: '5',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textInputAction: TextInputAction.next,
                        validator: _dueDayError,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Ville',
                        controller: _city,
                        hintText: 'Cotonou',
                        textInputAction: TextInputAction.next,
                        validator: Validators.requiredField,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Quartier',
                        controller: _district,
                        hintText: 'Fidjrossè',
                        textInputAction: TextInputAction.done,
                        validator: Validators.requiredField,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Obx(
              () => BottomCtaBar(
                primaryLabel: 'Enregistrer le logement',
                onPrimary: _save,
                isLoading: controller.isSubmitting.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
