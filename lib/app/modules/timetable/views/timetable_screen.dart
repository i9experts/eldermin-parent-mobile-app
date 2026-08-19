import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/timetable_controller.dart';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Best-effort parse of a period's time string (e.g. "08:00", "8:00 AM")
/// onto today's date, so "Day progress" can be derived from real current
/// time vs real period times. Returns null (never fabricated) if the
/// string can't be read.
DateTime? _parsePeriodTime(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
  if (match == null) return null;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final upper = raw.toUpperCase();
  if (upper.contains('PM') && hour < 12) hour += 12;
  if (upper.contains('AM') && hour == 12) hour = 0;
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

class TimetableScreen extends GetView<TimetableController> {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Timetable',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Obx(() {
        if (controller.loading.value && controller.timetable.value == null) {
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

        final timetable = controller.timetable.value;
        if (timetable == null) {
          return const AppEmptyView(
              icon: Icons.schedule_outlined,
              title: 'No timetable published yet',
              subtitle: "Your school hasn't set up this class's timetable.");
        }
        final today = controller.selectedDay.value;
        final allToday = (timetable['periods'] as List<dynamic>? ?? [])
            .where((p) => p['day'] == today)
            .toList();
        final periods = allToday
            .where((p) => p['type'] == 'regular')
            .toList()
          ..sort(
              (a, b) => (a['periodNo'] as num).compareTo(b['periodNo'] as num));
        final breaksCount = allToday
            .where((p) => (p['type']?.toString().toLowerCase() ?? '') == 'break')
            .length;
        final specialCount = allToday.length - periods.length - breaksCount;

        final now = DateTime.now();
        final completed = periods.where((p) {
          final end = _parsePeriodTime(p['endTime']?.toString());
          return end != null && end.isBefore(now);
        }).length;
        final progressPct =
            periods.isEmpty ? 0 : ((completed / periods.length) * 100).round();

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ScreenHeader(
                title: 'Timetable',
                caption: "Your child's organised learning day",
                selectLabel: _weekdayNames[controller.selectedDay.value],
                onSelectTap: () async {
                  final picked = await showAppWeekdayPicker(context,
                      initialWeekday: controller.selectedDay.value);
                  if (picked != null) controller.changeDay(picked);
                },
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.lg),
              CustomText(
                  text: '${timetable['gradeLevel'] ?? ''} ${timetable['sectionName'] ?? ''}'
                      '${controller.selectedDay.value == DateTime.now().weekday - 1 ? ' • Today' : ' • ${_weekdayNames[controller.selectedDay.value]}'}',
                  color: AppColors.muted,
                  fontSize: 11,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.md),
              StatsRow(items: [
                ('${periods.length}', 'Periods', null),
                ('$breaksCount', 'Breaks', null),
                ('$specialCount', 'Special', null),
              ]),
              if (periods.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                              text: 'Day progress',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          Flexible(
                            child: CustomText(
                                text:
                                    '$completed of ${periods.length} periods',
                                color: AppColors.muted,
                                fontSize: 10,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppProgressBar(percent: progressPct),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (periods.isEmpty)
                const AppEmptyView(
                    icon: Icons.weekend_outlined,
                    title: 'No classes scheduled today')
              else
                AppTimeline(
                  items: periods.map<(String, String, String, Color)>((p) {
                    return (
                      '${p['startTime'] ?? ''} - ${p['endTime'] ?? ''}',
                      p['subject'] ?? 'Period ${p['periodNo']}',
                      p['roomNo'] != null ? 'Room ${p['roomNo']}' : '',
                      AppColors.blue,
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      }),
    );
  }
}
