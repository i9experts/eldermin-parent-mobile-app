import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/chart_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/design/design.dart';
import '../../../../core/widgets/em_tab_heading.dart';
import '../../../../core/widgets/tab_state_list.dart';
import '../controllers/events_controller.dart';

const _categoryColors = {
  'academic': EmColors.primary,
  'sports': EmColors.accent,
  'exam': EmColors.error,
  'cultural': EmColors.statusLeave,
  'religious': EmColors.success,
  'parents': EmColors.primary,
  'holiday': EmColors.success,
  'trip': EmColors.statusLeave,
};

/// Calendar tab root (teacher tab-root pattern: [TabHeading] + [TabStateList], teacher `calendar_screen.dart:75-93` for the
/// calendar tab body and `classes_screen.dart:59-72` for the heading). The month chip opens the month picker (wired).
class EventsCalendarScreen extends StatelessWidget {
  const EventsCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EventsController());

    return Obx(() {
      final loading = controller.loading.value && controller.events.isEmpty;
      final TabListState state;
      if (loading) {
        state = TabListState.loading;
      } else if (controller.error.value != null) {
        state = TabListState.error;
      } else {
        state = TabListState.data;
      }

      final month = controller.selectedMonth.value;
      final day = controller.selectedDay.value;
      final eventDays = controller.daysWithEvents(month);
      final monthEvents = controller.eventsInMonth(month);
      final events = day == null ? monthEvents : controller.eventsOnDay(month, day);

      return TabStateList(
        state: state,
        onRefresh: controller.fetch,
        header: [
          const TabHeading(title: 'Calendar', caption: 'School events, exams and meetings'),
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: EmChip(
                key: const Key('month_chip'),
                label: DateFormat('MMMM yyyy').format(month),
                icon: Icons.expand_more_rounded,
                onTap: () async {
                  final picked = await showAppMonthPicker(context, initialMonth: month);
                  if (picked != null) controller.changeMonth(picked);
                },
              ),
            ),
          ),
        ],
        skeleton: const [
          ShimmerBone(width: double.infinity, height: 320, radius: EmRadius.card),
          SizedBox(height: EmSpacing.s12),
          ShimmerStatsRowSkeleton(count: 3),
          SizedBox(height: EmSpacing.s12),
          ShimmerListRowSkeleton(),
          ShimmerListRowSkeleton(),
          ShimmerListRowSkeleton(),
        ],
        errorMessage: controller.error.value,
        onRetry: controller.fetch,
        data: [
          AppCard(
            child: AppMonthCalendar(
              month: month,
              eventDays: eventDays,
              selectedDay: day,
              onDayTap: controller.toggleDay,
              onPrevMonth: controller.prevMonth,
              onNextMonth: controller.nextMonth,
            ),
          ),
          StatsRow(items: [
            ('${monthEvents.length}', 'Events', null),
            ('${monthEvents.where((e) => e['category'] == 'exam').length}', 'Exams', null),
            ('${monthEvents.where((e) => e['category'] == 'parents').length}', 'Meetings', null),
          ]),
          const SizedBox(height: EmSpacing.s8),
          SectionRow(title: day == null ? 'This month' : '$day ${DateFormat('MMMM').format(month)}'),
          if (events.isEmpty)
            AppEmptyView(
                icon: Icons.event_busy_outlined,
                title: day == null ? 'No events this month' : 'Nothing on this day',
                subtitle: day == null ? 'School events and important dates will show up here.' : 'Tap the date again to see the whole month.')
          else
            ...events.map((e) {
              final range = controller.rangeOf(e);
              final color = _categoryColors[e['category']] ?? EmColors.primary;
              return ListCardRow(
                icon: Icons.calendar_month_rounded,
                iconColor: color,
                title: e['title']?.toString() ?? 'Event',
                subtitle: [
                  if (range != null) _rangeLabel(range.$1, range.$2),
                  if (e['venue'] != null && e['venue'].toString().isNotEmpty) e['venue'].toString(),
                ].join(' • '),
                trailing: AppTag((e['category'] ?? 'event').toString(), style: TagStyle.info),
                onTap: () => _showEvent(context, e, range, color),
              );
            }),
        ],
      );
    });
  }

  static String _rangeLabel(DateTime s, DateTime e) {
    final f = DateFormat('d MMM yyyy');
    return s == e ? f.format(s) : '${f.format(s)} – ${f.format(e)}';
  }

  void _showEvent(BuildContext context, dynamic e, (DateTime, DateTime)? range, Color color) {
    final desc = e['description']?.toString() ?? '';
    final time = [e['startTime'], e['endTime']].where((t) => t != null && t.toString().isNotEmpty).join(' – ');
    final rows = <(IconData, String)>[
      if (range != null) (Icons.event_outlined, _rangeLabel(range.$1, range.$2)),
      if (time.isNotEmpty) (Icons.schedule_outlined, time),
      if (e['venue'] != null && e['venue'].toString().isNotEmpty) (Icons.place_outlined, e['venue'].toString()),
    ];
    EmBottomSheet.show<void>(
      context,
      title: e['title']?.toString() ?? 'Event',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(alignment: AlignmentDirectional.centerStart, child: AppTag((e['category'] ?? 'event').toString(), style: TagStyle.info)),
          const SizedBox(height: EmSpacing.s12),
          for (final r in rows)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s8),
              child: Row(children: [
                Icon(r.$1, size: 20, color: color),
                const SizedBox(width: EmSpacing.s12),
                Expanded(child: Text(r.$2, style: EmType.body.copyWith(color: EmColors.ink))),
              ]),
            ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: EmSpacing.s4),
            Text(desc, style: EmType.body.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
          ],
        ],
      ),
    );
  }
}
