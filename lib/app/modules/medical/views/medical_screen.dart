import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/medical_controller.dart';

class MedicalScreen extends GetView<MedicalController> {
  const MedicalScreen({super.key});

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: EmSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
              text: label,
              color: EmColors.textSecondary,
              fontSize: 10.5,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Flexible(
            child: CustomText(
                text: value,
                textAlign: TextAlign.right,
                color: EmColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _chipList(String title, List<dynamic> items, TagStyle style) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
                text: title,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: EmColors.primaryDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.map((i) => AppTag(i.toString(), style: style)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Medical information'),
      body: Obx(() {
        if (controller.loading.value && controller.medical.value == null) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: const [
                ShimmerScreenIntroSkeleton(withChip: false),
                SizedBox(height: EmSpacing.s12),
                ShimmerListRowSkeleton(),
                ShimmerListRowSkeleton(),
                ShimmerListRowSkeleton(),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }

        final m = controller.medical.value ?? {};
        final allergies = (m['allergies'] as List<dynamic>?) ?? [];
        final medications = (m['medications'] as List<dynamic>?) ?? [];
        final conditions = (m['conditions'] as List<dynamic>?) ?? [];
        final bloodGroup = m['bloodGroup']?.toString();
        final doctorName = m['doctorName']?.toString();
        final doctorPhone = m['doctorPhone']?.toString();
        final insuranceProvider = m['insuranceProvider']?.toString();
        final insurancePolicyNumber = m['insurancePolicyNumber']?.toString();
        final specialNeedsDetail = m['specialNeedsDetail']?.toString();

        final hasAnything = (bloodGroup?.isNotEmpty ?? false) ||
            allergies.isNotEmpty ||
            medications.isNotEmpty ||
            conditions.isNotEmpty ||
            (doctorName?.isNotEmpty ?? false) ||
            (insuranceProvider?.isNotEmpty ?? false) ||
            (specialNeedsDetail?.isNotEmpty ?? false);

        if (!hasAnything) {
          return const AppEmptyView(
            icon: Icons.medical_information_outlined,
            title: 'No medical information on file',
            subtitle: "Your school hasn't recorded any medical details yet.",
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              const ScreenIntro(caption: 'Health record on file with the school'),
              const SizedBox(height: EmSpacing.s16),
              if (bloodGroup != null && bloodGroup.isNotEmpty) ...[
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CustomText(
                          text: 'Blood group',
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: EmColors.primaryDark),
                      AppTag(bloodGroup, style: TagStyle.red),
                    ],
                  ),
                ),
                const SizedBox(height: EmSpacing.s12),
              ],
              _chipList('Allergies', allergies, TagStyle.red),
              _chipList('Medications', medications, TagStyle.amber),
              _chipList('Conditions', conditions, TagStyle.info),
              if ((doctorName?.isNotEmpty ?? false) || (doctorPhone?.isNotEmpty ?? false)) ...[
                const SectionRow(title: 'Doctor'),
                AppCard(
                  child: Column(
                    children: [
                      _row('Name', doctorName?.isNotEmpty == true ? doctorName! : '—'),
                      const Divider(),
                      _row('Phone', doctorPhone?.isNotEmpty == true ? doctorPhone! : '—'),
                    ],
                  ),
                ),
                const SizedBox(height: EmSpacing.s12),
              ],
              if ((insuranceProvider?.isNotEmpty ?? false) || (insurancePolicyNumber?.isNotEmpty ?? false)) ...[
                const SectionRow(title: 'Insurance'),
                AppCard(
                  child: Column(
                    children: [
                      _row('Provider', insuranceProvider?.isNotEmpty == true ? insuranceProvider! : '—'),
                      const Divider(),
                      _row('Policy number', insurancePolicyNumber?.isNotEmpty == true ? insurancePolicyNumber! : '—'),
                    ],
                  ),
                ),
                const SizedBox(height: EmSpacing.s12),
              ],
              if (specialNeedsDetail != null && specialNeedsDetail.isNotEmpty) ...[
                const SectionRow(title: 'Special needs'),
                AppCard(
                    child: CustomText(
                        text: specialNeedsDetail,
                        color: EmColors.ink,
                        fontSize: 12.5)),
              ],
            ],
          ),
        );
      }),
    );
  }
}
