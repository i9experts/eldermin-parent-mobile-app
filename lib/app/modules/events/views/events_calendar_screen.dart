import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/chart_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
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

      final month = controller.selectedMonth.value;
      final day = controller.selectedDay.value;
      final eventDays = controller.daysWithEvents(month);
      final monthEvents = controller.eventsInMonth(month);
      final events = day == null ? monthEvents : controller.eventsOnDay(month, day);

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
            AppCard(
                child: AppMonthCalendar(
              month: month,
              eventDays: eventDays,
              selectedDay: day,
              onDayTap: controller.toggleDay,
              onPrevMonth: controller.prevMonth,
              onNextMonth: controller.nextMonth,
            )),
            const SizedBox(height: AppSpacing.md),
            StatsRow(items: [
              ('${monthEvents.length}', 'Events', null),
              (
                '${monthEvents.where((e) => e['category'] == 'exam').length}',
                'Exams',
                null
              ),
              (
                '${monthEvents.where((e) => e['category'] == 'parents').length}',
                'Meetings',
                null
              )
            ]),
            const SizedBox(height: AppSpacing.md),
            SectionRow(
                title: day == null
                    ? 'This month'
                    : '$day ${DateFormat('MMMM').format(month)}'),
            if (events.isEmpty)
              AppEmptyView(
                  icon: Icons.event_busy_outlined,
                  title: day == null ? 'No events this month' : 'Nothing on this day',
                  subtitle: day == null
                      ? 'School events and important dates will show up here.'
                      : 'Tap the date again to see the whole month.')
            else
              ...events.map((e) {
                final range = controller.rangeOf(e);
                final color = _categoryColors[e['category']] ?? AppColors.blue;
                return ListCardRow(
                  icon: Icons.calendar_month_rounded,
                  iconColor: color,
                  title: e['title']?.toString() ?? 'Event',
                  subtitle: [
                    if (range != null) _rangeLabel(range.$1, range.$2),
                    if (e['venue'] != null && e['venue'].toString().isNotEmpty) e['venue'].toString(),
                  ].join(' • '),
                  trailing: AppTag((e['category'] ?? 'event').toString(),
                      style: TagStyle.info),
                  onTap: () => _showEvent(context, e, range, color),
                );
              }),
          ],
        ),
      );
    });
  }

  static String _rangeLabel(DateTime s, DateTime e) {
    final f = DateFormat('d MMM yyyy');
    return s == e ? f.format(s) : '${f.format(s)} – ${f.format(e)}';
  }

  void _showEvent(BuildContext context, dynamic e, (DateTime, DateTime)? range, Color color) {
    final desc = e['description']?.toString() ?? '';
    final time = [e['startTime'], e['endTime']]
        .where((t) => t != null && t.toString().isNotEmpty)
        .join(' – ');
    final rows = <(IconData, String)>[
      if (range != null) (Icons.event_outlined, _rangeLabel(range.$1, range.$2)),
      if (time.isNotEmpty) (Icons.schedule_outlined, time),
      if (e['venue'] != null && e['venue'].toString().isNotEmpty)
        (Icons.place_outlined, e['venue'].toString()),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: CustomText(
                      text: e['title']?.toString() ?? 'Event',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.primaryColor),
                ),
                const SizedBox(width: 8),
                AppTag((e['category'] ?? 'event').toString(), style: TagStyle.info),
              ]),
              const SizedBox(height: 14),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(r.$1, size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(child: CustomText(text: r.$2, fontSize: 13, color: AppColors.ink)),
                  ]),
                ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                CustomText(text: desc, fontSize: 13, color: AppColors.muted),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
