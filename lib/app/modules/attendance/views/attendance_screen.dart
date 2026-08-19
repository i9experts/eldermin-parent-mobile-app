import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/chart_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/attendance_controller.dart';

class AttendanceScreen extends GetView<AttendanceController> {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Attendance',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18)),
      body: Obx(() {
        if (controller.loading.value && controller.records.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerDateStripSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerHeroCardSkeleton(),
                const SizedBox(height: AppSpacing.md),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.md),
                const ShimmerChartSkeleton(),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(6),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final records = controller.recordsForSelectedMonth;
        final total = records.length;
        final present = records.where((r) => r['status'] == 'present').length;
        final absent = records.where((r) => r['status'] == 'absent').length;
        final late = records.where((r) => r['status'] == 'late').length;
        final pct = total == 0 ? 0 : ((present / total) * 100).round();

        final monthly = controller.monthlyAttendancePercent;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ScreenHeader(
                title: 'Attendance',
                caption: 'Consistency and punctuality',
                selectLabel: DateFormat('MMMM yyyy')
                    .format(controller.selectedMonth.value),
                onSelectTap: () async {
                  final picked = await showAppMonthPicker(
                    context,
                    initialMonth: controller.selectedMonth.value,
                    maxMonth: DateTime.now(),
                  );
                  if (picked != null) controller.changeMonth(picked);
                },
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.lg),
              HeroCard(
                kicker: 'Monthly attendance',
                value: total == 0 ? '—' : '$pct%',
                trend: total == 0
                    ? 'No attendance recorded yet'
                    : '$pct% attendance this month',
                percent: pct,
                ringColor: AppColors.secondryColor,
                metrics: [
                  ('$present', 'Present'),
                  ('$absent', 'Absent'),
                  ('$late', 'Late'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              StatsRow(items: [
                ('$present', 'Present', null),
                ('$absent', 'Absent', null),
                ('$late', 'Late', null)
              ]),
              if (monthly.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText(
                          text: '6-month trend',
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.primaryColor),
                      const SizedBox(height: 10),
                      AppBarChart(data: monthly),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (records.isEmpty)
                const AppEmptyView(
                    icon: Icons.event_busy_outlined,
                    title: 'No attendance recorded yet')
              else
                ...records.take(30).map((r) {
                  final date = r['date'] != null
                      ? DateTime.tryParse(r['date'].toString())
                      : null;
                  final status = r['status'] as String? ?? '';
                  final style = status == 'present'
                      ? TagStyle.green
                      : (status == 'absent' ? TagStyle.red : TagStyle.amber);
                  return AppCard(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomText(
                                text: date != null
                                    ? '${date.day}/${date.month}/${date.year}'
                                    : '—',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          AppTag(
                              status.isEmpty
                                  ? '—'
                                  : status[0].toUpperCase() +
                                      status.substring(1),
                              style: style),
                        ]),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
