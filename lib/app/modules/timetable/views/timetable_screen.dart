import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
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
    return EmScaffold(
      appBar: EmAppBar(title: 'Timetable'),
      body: Obx(() {
        if (controller.loading.value && controller.timetable.value == null) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(),
                const SizedBox(height: EmSpacing.s16),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: EmSpacing.s12),
                const ShimmerChartSkeleton(),
                const SizedBox(height: EmSpacing.s12),
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
        // UI index is Monday-first (0..6); backend `day` is 0=Sunday.
        final today = (controller.selectedDay.value + 1) % 7;
        final allToday = (timetable['periods'] as List<dynamic>? ?? [])
            .where((p) => p['day'] == today)
            .toList();
        final periods = allToday
            .where((p) => p['type'] != 'break' && p['type'] != 'free')
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
            padding: EmSpacing.listPadding,
            children: [
              ScreenIntro(
                caption: "Your child's organised learning day",
                selectLabel: _weekdayNames[controller.selectedDay.value],
                onSelectTap: () async {
                  final picked = await showAppWeekdayPicker(context,
                      initialWeekday: controller.selectedDay.value);
                  if (picked != null) controller.changeDay(picked);
                },
              ),
              Text(
                  '${timetable['gradeLevel'] ?? ''} ${timetable['sectionName'] ?? ''}'
                  '${controller.selectedDay.value == DateTime.now().weekday - 1 ? ' • Today' : ' • ${_weekdayNames[controller.selectedDay.value]}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EmType.body.copyWith(color: EmColors.textSecondary)),
              const SizedBox(height: EmSpacing.s12),
              StatsRow(items: [
                ('${periods.length}', 'Periods', null),
                ('$breaksCount', 'Breaks', null),
                ('$specialCount', 'Special', null),
              ]),
              if (periods.isNotEmpty) ...[
                const SizedBox(height: EmSpacing.s12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Day progress', style: EmType.label.copyWith(color: EmColors.ink)),
                          const SizedBox(width: EmSpacing.s8),
                          Flexible(
                            child: Text('$completed of ${periods.length} periods',
                                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: EmType.caption.copyWith(color: EmColors.textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: EmSpacing.s12),
                      AppProgressBar(percent: progressPct),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: EmSpacing.s12),
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
                      EmColors.primary,
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
