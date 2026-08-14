import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final eventsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(parentApiProvider);
  return api.getEvents();
});

const _categoryColors = {
  'academic': AppColors.blue, 'sports': AppColors.amber, 'exam': AppColors.red,
  'cultural': AppColors.purple, 'religious': AppColors.green, 'parents': AppColors.blue,
  'holiday': AppColors.green, 'trip': AppColors.purple,
};

class EventsCalendarScreen extends ConsumerWidget {
  const EventsCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(eventsProvider);

    return asyncData.when(
      loading: () => const AppLoader(),
      error: (e, _) => AppErrorView(message: 'Could not load events', onRetry: () => ref.invalidate(eventsProvider)),
      data: (events) {
        if (events.isEmpty) {
          return const AppEmptyView(icon: Icons.event_busy_outlined, title: 'No upcoming events', subtitle: 'School events and important dates will show up here.');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(eventsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              StatsRow(items: [('${events.length}', 'Events', null), ('${events.where((e) => e['category'] == 'exam').length}', 'Exams', null), ('${events.where((e) => e['category'] == 'parents').length}', 'Meetings', null)]),
              const SizedBox(height: AppSpacing.md),
              ...events.map((e) {
                final start = e['startDate'] != null ? DateTime.tryParse(e['startDate'].toString()) : null;
                final color = _categoryColors[e['category']] ?? AppColors.blue;
                return ListCardRow(
                  icon: Icons.calendar_month_rounded,
                  iconColor: color,
                  title: e['title'] ?? 'Event',
                  subtitle: start != null ? '${start.day}/${start.month}/${start.year}${e['venue'] != null ? ' \u2022 ${e['venue']}' : ''}' : (e['venue'] ?? ''),
                  trailing: AppTag((e['category'] ?? 'event').toString(), style: TagStyle.info),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
