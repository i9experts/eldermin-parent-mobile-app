import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/circulars_controller.dart';

class CircularsScreen extends GetView<CircularsController> {
  const CircularsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'School updates',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18)),
      body: Obx(() {
        if (controller.loading.value && controller.circulars.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerDateStripSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.lg),
                ...shimmerListRows(6),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final circulars = controller.circulars;
        final selectedMonth = controller.selectedMonth.value;
        final circularsForSelectedMonth = circulars.where((raw) {
          final c = raw as Map;
          final d = DateTime.tryParse(
              (c['effectiveDate'] ?? c['createdAt'])?.toString() ?? '');
          return d != null &&
              d.year == selectedMonth.year &&
              d.month == selectedMonth.month;
        }).toList();
        final thisMonth = circularsForSelectedMonth.length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ScreenHeader(
                title: 'School updates',
                caption: 'Circulars, notices and acknowledgements',
                selectLabel: DateFormat('MMMM yyyy').format(selectedMonth),
                onSelectTap: () async {
                  final picked = await showAppMonthPicker(
                    context,
                    initialMonth: selectedMonth,
                  );
                  if (picked != null) controller.changeMonth(picked);
                },
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${circulars.length}', 'Published', null),
                ('$thisMonth', 'This month', null),
                (
                  '${circulars.where((c) => c['category'] == 'circular').length}',
                  'Circulars',
                  null
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              const SectionRow(title: 'Notices'),
              if (circularsForSelectedMonth.isEmpty)
                const AppEmptyView(
                    icon: Icons.campaign_outlined,
                    title: 'No school updates yet')
              else
                ...circularsForSelectedMonth.map((raw) {
                  final c = Map<String, dynamic>.from(raw as Map);
                  final date = DateTime.tryParse(
                      (c['effectiveDate'] ?? c['createdAt'])?.toString() ?? '');
                  final category = c['category']?.toString() ?? 'notice';
                  return ListCardRow(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.blue,
                    title: c['title']?.toString() ?? 'Notice',
                    subtitle: [
                      if (date != null)
                        '${date.day}/${date.month}/${date.year}',
                      category,
                    ].join(' • '),
                    trailing: AppTag(category, style: TagStyle.info),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
