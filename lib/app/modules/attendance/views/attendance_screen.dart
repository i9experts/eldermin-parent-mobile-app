import 'package:flutter/material.dart';
import '../../../../core/utils/greeting.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/chart_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../controllers/attendance_controller.dart';

class AttendanceScreen extends GetView<AttendanceController> {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Attendance'),
      body: Obx(() {
        if (controller.loading.value && controller.records.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(),
                const SizedBox(height: EmSpacing.s16),
                const ShimmerHeroCardSkeleton(),
                const SizedBox(height: EmSpacing.s12),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: EmSpacing.s12),
                const ShimmerChartSkeleton(),
                const SizedBox(height: EmSpacing.s12),
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
        // A late arrival still attended that day, so it counts toward attendance.
        final pct = total == 0 ? 0 : (((present + late) / total) * 100).round();

        final monthly = controller.monthlyAttendancePercent;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              ScreenIntro(
                caption: 'Consistency and punctuality',
                selectLabel: DateFormat('MMMM yyyy')
                    .format(controller.selectedMonth.value),
                onSelectTap: () async {
                  final picked = await showAppMonthPicker(
                    context,
                    initialMonth: controller.selectedMonth.value,
                    maxMonth: uiNow(),
                  );
                  if (picked != null) controller.changeMonth(picked);
                },
              ),
              HeroCard(
                kicker: 'Monthly attendance',
                value: total == 0 ? '—' : '$pct%',
                trend: total == 0
                    ? 'No attendance recorded yet'
                    : '$pct% attendance this month',
                percent: pct,
                metricIcons: const [Icons.check_circle_outline_rounded, Icons.cancel_outlined, Icons.schedule_rounded],
                metrics: [
                  ('$present', 'Present'),
                  ('$absent', 'Absent'),
                  ('$late', 'Late'),
                ],
              ),
              const SizedBox(height: EmSpacing.s12),
              if (monthly.isNotEmpty) ...[
                const SizedBox(height: EmSpacing.s12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('6-month trend', style: EmType.label.copyWith(color: EmColors.ink)),
                      const SizedBox(height: EmSpacing.s12),
                      AppBarChart(data: monthly),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: EmSpacing.s12),
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
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.row),
                    child: EmCard(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.s16, vertical: EmSpacing.s12),
                      child: Row(children: [
                        Expanded(
                          child: Text(date != null ? '${date.day}/${date.month}/${date.year}' : '—',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.bodyLarge.copyWith(color: EmColors.ink)),
                        ),
                        const SizedBox(width: EmSpacing.s8),
                        AppTag(status.isEmpty ? '—' : (status[0].toUpperCase() + status.substring(1)).replaceAll('_', ' '), style: style),
                      ]),
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
