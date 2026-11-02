import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/property_model.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/atoms/step_progress_bar.dart';
import '../../components/molecules/bottom_cta_bar.dart';
import '../../components/molecules/photo_picker.dart';
import '../../components/molecules/selection_chip.dart';
import 'listing_form_controller.dart';

/// C3 et C4 : nouvelle annonce en deux étapes (où ? puis prix et photos).
class ListingFormPage extends StatefulWidget {
  const ListingFormPage({super.key});

  @override
  State<ListingFormPage> createState() => _ListingFormPageState();
}

class _ListingFormPageState extends State<ListingFormPage> {
  final _stepOneKey = GlobalKey<FormState>();
  final _stepTwoKey = GlobalKey<FormState>();

  final _city = TextEditingController();
  final _district = TextEditingController();
  final _rent = TextEditingController();
  final _deposit = TextEditingController();
  final _description = TextEditingController();

  final controller = Get.find<ListingFormController>();
  late final Worker _housingWatcher;

  @override
  void initState() {
    super.initState();
    // Choisir un logement préremplit la ville, le quartier et le loyer.
    // Déjà choisi à l'ouverture (liste chargée avant la page) : on préremplit tout de suite.
    _prefill(controller.housing.value);
    _housingWatcher = ever(controller.housing, _prefill);
  }

  void _prefill(HousingModel? housing) {
    if (housing == null) return;
    _city.text = housing.city;
    _district.text = housing.district;
    if (_rent.text.isEmpty) _rent.text = '${housing.rent}';
  }

  @override
  void dispose() {
    _housingWatcher.dispose();
    _city.dispose();
    _district.dispose();
    _rent.dispose();
    _deposit.dispose();
    _description.dispose();
    super.dispose();
  }

  int _amount(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  void _next() {
    if (_stepOneKey.currentState?.validate() ?? false) controller.goToStep(1);
  }

  Future<void> _publish() async {
    if (!(_stepTwoKey.currentState?.validate() ?? false)) return;
    await controller.publish(
      city: _city.text,
      district: _district.text,
      rent: _amount(_rent),
      deposit: _amount(_deposit),
      description: _description.text,
    );
  }

  String? _rentError(String? value) {
    final amount = int.tryParse((value ?? '').replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (amount == 0) return 'Indiquez le loyer.';
    if (amount < 1000) return 'Le loyer doit être d’au moins 1 000 FCFA.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Obx(() {
            final second = controller.step.value == 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
                  child: Row(
                    children: [
                      AppBackButton(onPressed: controller.back),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text('Nouvelle annonce', style: AppTextStyles.section)),
                      Text('Étape ${controller.step.value + 1} sur 2', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: StepProgressBar(current: controller.step.value + 1, total: 2),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: second ? _stepTwo() : _stepOne(),
                  ),
                ),
                BottomCtaBar(
                  primaryLabel: second ? 'Publier l’annonce' : 'Continuer',
                  onPrimary: second ? _publish : _next,
                  isLoading: controller.isSubmitting.value,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ C3

  Widget _stepOne() {
    return Form(
      key: _stepOneKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Où se trouve le logement ?', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),
          if (controller.housings.isNotEmpty) ...[
            Text('Logement concerné', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final h in controller.housings)
                  SelectionChip(
                    label: h.title,
                    selected: controller.housing.value?.id == h.id,
                    onTap: () => controller.selectHousing(h),
                  ),
              ],
            ),
          ] else ...[
            Text('Type de logement', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (t, label) in [
                  (AccommodationType.HOUSE, 'Maison'),
                  (AccommodationType.ROOM, 'Chambre'),
                  (AccommodationType.OTHER, 'Autre'),
                ])
                  SelectionChip(
                    label: label,
                    selected: controller.type.value == t,
                    onTap: () => controller.selectType(t),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Ville',
            controller: _city,
            hintText: 'Abomey-Calavi',
            textInputAction: TextInputAction.next,
            validator: Validators.requiredField,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Quartier',
            controller: _district,
            hintText: 'Togoudo',
            textInputAction: TextInputAction.done,
            validator: Validators.requiredField,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ C4

  Widget _stepTwo() {
    return Form(
      key: _stepTwoKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prix et photos', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Loyer par mois',
            controller: _rent,
            suffixText: 'FCFA',
            hintText: '200000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            validator: _rentError,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Caution',
            controller: _deposit,
            suffixText: 'FCFA',
            hintText: '400000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Nombre de pièces', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final n in [1, 2, 3, 4, 5])
                SelectionChip(
                  label: n == 5 ? '5+' : '$n',
                  selected: controller.rooms.value == n,
                  onTap: () => controller.selectRooms(n),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PhotoPicker(
            photos: controller.photos.toList(),
            onAdd: controller.pickPhotos,
            onRemove: controller.removePhoto,
            max: ListingFormController.maxPhotos,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Description (facultatif)',
            controller: _description,
            hintText: 'Villa avec cour, eau et électricité, quartier calme.',
            keyboardType: TextInputType.multiline,
            maxLines: 4,
            minLines: 3,
          ),
        ],
      ),
    );
  }
}
