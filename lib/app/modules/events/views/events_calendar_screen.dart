import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/chart_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../controllers/events_controller.dart';

const _categoryColors = {
  'academic': AppColors.blue,
  'sports': AppColors.amber,
  'exam': AppColors.red,
  'cultural': AppColors.purple,
  'religious': AppColors.secondryColor,
  'parents': AppColors.blue,
  'holiday': AppColors.secondryColor,
  'trip': AppColors.purple,
};

class EventsCalendarScreen extends StatelessWidget {
  const EventsCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EventsController());

    return Obx(() {
      if (controller.loading.value && controller.events.isEmpty) {
        return AppShimmer(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ShimmerScreenHeaderSkeleton(),
              const SizedBox(height: AppSpacing.md),
              const ShimmerBone(width: double.infinity, height: 300, radius: AppRadius.lg),
              const SizedBox(height: AppSpacing.md),
              const ShimmerStatsRowSkeleton(count: 3),
              const SizedBox(height: AppSpacing.md),
              ...shimmerListRows(4),
            ],
          ),
        );
      }
      if (controller.error.value != null) {
        return AppErrorView(
            message: controller.error.value!, onRetry: controller.fetch);
      }

      final allEvents = controller.events;
      final month = controller.selectedMonth.value;
      final eventDays = <int>{
        for (final e in allEvents)
          if (e['startDate'] != null)
            if (DateTime.tryParse(e['startDate'].toString()) case final d?
                when d.year == month.year && d.month == month.month)
              d.day,
      };
      final events = allEvents.where((e) {
        final d = e['startDate'] != null
            ? DateTime.tryParse(e['startDate'].toString())
            : null;
        if (d == null) return true;
        return d.year == month.year && d.month == month.month;
      }).toList();

      return RefreshIndicator(
        onRefresh: controller.fetch,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            ScreenHeader(
              title: 'Calendar',
              caption: 'School events, exams and meetings',
              selectLabel: DateFormat('MMMM yyyy').format(month),
              onSelectTap: () async {
                final picked = await showAppMonthPicker(
                  context,
                  initialMonth: month,
                );
                if (picked != null) controller.changeMonth(picked);
              },
            ),
            AppCard(child: AppMonthCalendar(month: month, eventDays: eventDays)),
            const SizedBox(height: AppSpacing.md),
            if (events.isEmpty)
              const AppEmptyView(
                  icon: Icons.event_busy_outlined,
                  title: 'No upcoming events',
                  subtitle:
                      'School events and important dates will show up here.')
            else ...[
              StatsRow(items: [
                ('${events.length}', 'Events', null),
                (
                  '${events.where((e) => e['category'] == 'exam').length}',
                  'Exams',
                  null
                ),
                (
                  '${events.where((e) => e['category'] == 'parents').length}',
                  'Meetings',
                  null
                )
              ]),
              const SizedBox(height: AppSpacing.md),
              ...events.map((e) {
                final start = e['startDate'] != null
                    ? DateTime.tryParse(e['startDate'].toString())
                    : null;
                final color = _categoryColors[e['category']] ?? AppColors.blue;
                return ListCardRow(
                  icon: Icons.calendar_month_rounded,
                  iconColor: color,
                  title: e['title'] ?? 'Event',
                  subtitle: start != null
                      ? '${start.day}/${start.month}/${start.year}${e['venue'] != null ? ' • ${e['venue']}' : ''}'
                      : (e['venue'] ?? ''),
                  trailing: AppTag((e['category'] ?? 'event').toString(),
                      style: TagStyle.info),
                );
              }),
            ],
          ],
        ),
      );
    });
  }
}
