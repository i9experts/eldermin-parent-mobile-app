import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/homework_controller.dart';

class HomeworkScreen extends GetView<HomeworkController> {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Homework',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      body: Obx(() {
        if (controller.loading.value && controller.items.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerDateStripSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.md),
                const ShimmerChartSkeleton(),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(5),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final items = controller.items;
        final filtered = controller.filtered;
        final completedCount = items
            .where((h) => h['status'] == 'submitted' || h['status'] == 'graded')
            .length;
        final pendingCount = items.length - completedCount;
        final completionPct =
            items.isEmpty ? 0 : ((completedCount / items.length) * 100).round();

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ScreenHeader(
                title: 'Homework',
                caption: 'Tasks, submissions and feedback',
                selectLabel:
                    DateFormat('MMMM yyyy').format(controller.selectedMonth.value),
                onSelectTap: () async {
                  final picked = await showAppMonthPicker(
                    context,
                    initialMonth: controller.selectedMonth.value,
                  );
                  if (picked != null) controller.changeMonth(picked);
                },
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${items.length}', 'Assigned', null),
                ('$completedCount', 'Completed', null),
                ('$pendingCount', 'Pending', null),
              ]),
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DonutRing(percent: completionPct, color: AppColors.blue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomText(
                                text: 'Weekly completion',
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.primaryColor),
                            const SizedBox(height: 10),
                            _LegendRow(
                                color: AppColors.secondryColor,
                                label: 'Submitted',
                                value: '$completedCount'),
                            const SizedBox(height: 6),
                            _LegendRow(
                                color: AppColors.amber,
                                label: 'Pending',
                                value: '$pendingCount'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SegmentedControl(
                  options: const ['All tasks', 'Pending', 'Submitted'],
                  selectedIndex: controller.filter.value,
                  onChanged: controller.changeFilter),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
                const AppEmptyView(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Nothing here',
                    subtitle: 'No homework matches this filter.')
              else
                ...filtered.map((h) {
                  final due = h['dueDate'] != null
                      ? DateTime.tryParse(h['dueDate'].toString())
                      : null;
                  final isSubmitted =
                      h['status'] == 'submitted' || h['status'] == 'graded';
                  final isOverdue = !isSubmitted &&
                      due != null &&
                      due.isBefore(DateTime.now());
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: CustomText(
                                  text: h['subject'] ?? 'Subject',
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryColor,
                                  fontSize: 12,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          AppTag(
                            isSubmitted
                                ? 'Submitted'
                                : (isOverdue
                                    ? 'Overdue'
                                    : (due != null
                                        ? 'Due ${due.day}/${due.month}'
                                        : 'Pending')),
                            style: isSubmitted
                                ? TagStyle.green
                                : (isOverdue ? TagStyle.red : TagStyle.amber),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        CustomText(
                            text: h['title'] ?? h['description'] ?? '',
                            color: AppColors.muted,
                            fontSize: 10.5,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        AppProgressBar(
                            percent: isSubmitted ? 100 : (isOverdue ? 20 : 60),
                            color: isSubmitted
                                ? AppColors.secondryColor
                                : (isOverdue
                                    ? AppColors.red
                                    : AppColors.amber)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: CustomText(
              text: label,
              color: AppColors.muted,
              fontSize: 10,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        CustomText(
            text: value,
            color: AppColors.primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w800),
      ],
    );
  }
}
