import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/models/rental_model.dart';
import '../../components/atoms/app_back_button.dart';
import '../../components/atoms/app_card.dart';
import '../../components/atoms/screen_title.dart';
import '../../components/atoms/status_text.dart';
import '../../components/molecules/bottom_cta_bar.dart';
import '../../components/molecules/code_input.dart';
import '../../components/molecules/info_row.dart';
import '../../shared/load_status.dart';
import '../../shared/loading_view.dart';
import 'join_housing_controller.dart';

/// B1 Rejoindre mon logement.
class JoinHousingPage extends StatefulWidget {
  const JoinHousingPage({super.key});

  @override
  State<JoinHousingPage> createState() => _JoinHousingPageState();
}

class _JoinHousingPageState extends State<JoinHousingPage> {
  final _code = TextEditingController();
  final controller = Get.find<JoinHousingController>();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _notTheRightOne() {
    _code.clear();
    controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const Align(alignment: Alignment.centerLeft, child: AppBackButton()),
            const SizedBox(height: AppSpacing.md),
            const ScreenTitle(
              title: 'Entrez le code de votre logement',
              subtitle: 'Votre propriétaire vous l’a donné par message ou de vive voix.',
              large: false,
            ),
            const SizedBox(height: AppSpacing.xl),
            Obx(
              () => CodeInput(
                controller: _code,
                autofocus: true,
                onChanged: controller.onCodeChanged,
                errorText: controller.codeError.value,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Obx(() {
              switch (controller.lookupStatus.value) {
                case LoadStatus.loading:
                  return const SizedBox(height: 120, child: LoadingView());
                case LoadStatus.loaded:
                  final housing = controller.housing.value;
                  return housing == null ? const SizedBox.shrink() : _Preview(housing: housing);
                case LoadStatus.initial:
                case LoadStatus.failure:
                  return const SizedBox.shrink();
              }
            }),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        final found = controller.housing.value != null;
        if (!found) return const SizedBox.shrink();
        return BottomCtaBar(
          primaryLabel: 'Oui, c’est mon logement',
          onPrimary: controller.confirm,
          isLoading: controller.joining.value,
          secondaryLabel: 'Ce n’est pas le bon logement',
          onSecondary: _notTheRightOne,
        );
      }),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.housing});

  final HousingPreview housing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusText('Code reconnu', kind: StatusKind.ok),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(housing.title, style: AppTextStyles.section),
                    const SizedBox(height: AppSpacing.xs),
                    Text(housing.location, style: AppTextStyles.caption),
                  ],
                ),
              ),
              InfoRow(label: 'Loyer', value: '${CurrencyFormatter.format(housing.rent)} /mois'),
              if (housing.dueDay != null)
                InfoRow(label: 'À payer avant le', value: '${housing.dueDay} de chaque mois'),
              InfoRow(
                label: 'Propriétaire',
                value: housing.ownerName,
                showDivider: false,
                valueWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        housing.ownerName,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodyStrong,
                      ),
                    ),
                    if (housing.ownerVerified) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const StatusText('Vérifié', kind: StatusKind.ok),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
