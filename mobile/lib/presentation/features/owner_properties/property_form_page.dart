import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/presentation/routes/app_routes.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/property_model.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_button.dart';
import '../../components/atoms/app_chip.dart';
import '../../components/atoms/app_text_field.dart';
import '../../components/atoms/screen_title.dart';
import '../../components/molecules/housing_code_box.dart';
import 'property_controller.dart';

/// Écran C6 : Ajouter un logement / locataire.
/// Conforme à la règle GetX : StatefulWidget isolant les TextEditingController.
class PropertyFormPage extends StatefulWidget {
  const PropertyFormPage({super.key});

  @override
  State<PropertyFormPage> createState() => _PropertyFormPageState();
}

class _PropertyFormPageState extends State<PropertyFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _cityController = TextEditingController(text: 'Cotonou');
  final _districtController = TextEditingController();
  final _rentController = TextEditingController();
  final _dueDayController = TextEditingController(text: '5');

  AccommodationType _selectedType = AccommodationType.HOUSE;
  HousingModel? _createdHousing;

  final PropertyController controller = Get.find<PropertyController>();

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _rentController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rent = int.tryParse(_rentController.text.trim()) ?? 0;
    final dueDay = int.tryParse(_dueDayController.text.trim()) ?? 5;

    final created = await controller.createHousing(
      title: _titleController.text.trim(),
      type: _selectedType,
      rent: rent,
      dueDay: dueDay,
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
    );

    if (created != null && mounted) {
      setState(() {
        _createdHousing = created;
      });
    }
  }

  void _shareCode(String code, String title) {
    Share.share(
      'Rejoignez le logement "$title" sur LofiSoft en saisissant ce code : $code',
      subject: 'Code logement LofiSoft',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          _createdHousing == null ? 'Ajouter un logement' : 'Logement créé',
          style: AppTextStyles.section,
        ),
      ),
      body: SafeArea(
        child: _createdHousing != null
            ? _buildSuccessView(_createdHousing!)
            : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    const gap = SizedBox(height: AppSpacing.md);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTitle(
              title: 'Nouveau logement',
              subtitle:
                  'Indiquez les paramètres du bail. Un code unique sera généré automatiquement.',
              large: false,
            ),
            const SizedBox(height: AppSpacing.xl),

            AppTextField(
              label: 'Nom du logement',
              hintText: 'ex. Appartement 2B, Studio meublé...',
              controller: _titleController,
              validator: Validators.requiredField,
            ),
            gap,

            Text('Type de logement', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppChip(
                    label: 'Maison / Appart.',
                    selected: _selectedType == AccommodationType.HOUSE,
                    onTap: () =>
                        setState(() => _selectedType = AccommodationType.HOUSE),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppChip(
                    label: 'Chambre / Studio',
                    selected: _selectedType == AccommodationType.ROOM,
                    onTap: () =>
                        setState(() => _selectedType = AccommodationType.ROOM),
                  ),
                ),
              ],
            ),
            gap,

            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: AppTextField(
                    label: 'Ville',
                    hintText: 'ex. Cotonou',
                    controller: _cityController,
                    validator: Validators.requiredField,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 5,
                  child: AppTextField(
                    label: 'Quartier',
                    hintText: 'ex. Fidjrossè',
                    controller: _districtController,
                    validator: Validators.requiredField,
                  ),
                ),
              ],
            ),
            gap,

            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: AppTextField(
                    label: 'Loyer mensuel',
                    hintText: '150 000',
                    controller: _rentController,
                    suffixText: AppConstants.currency,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      final parsed = int.tryParse(v);
                      if (parsed == null || parsed < 1000)
                        return 'Min. 1 000 FCFA';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 4,
                  child: AppTextField(
                    label: 'Échéance',
                    hintText: '5',
                    controller: _dueDayController,
                    suffixText: 'du mois',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      final day = int.tryParse(v);
                      if (day == null || day < 1 || day > 28) return '1 à 28';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            Obx(
              () => AppButton(
                label: 'Enregistrer le logement',
                isLoading: controller.isSubmitting.value,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(HousingModel housing) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.green,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Logement enregistré !',
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Partagez ce code avec votre locataire pour qu’il rejoigne ce logement depuis son application.',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          HousingCodeBox(
            code: housing.code,
            onShare: () => _shareCode(housing.code, housing.title),
          ),
          const Spacer(),
          AppButton(
            label: 'Voir mes logements',
            onPressed: () => Get.offNamed(AppRoutes.ownerProperties),
          ),
        ],
      ),
    );
  }
}
