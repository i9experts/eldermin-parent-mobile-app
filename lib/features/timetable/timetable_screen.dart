import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final timetableProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, studentId) async {
  final api = ref.watch(parentApiProvider);
  return api.getTimetable(studentId);
});

class TimetableScreen extends ConsumerWidget {
  final String studentId;
  const TimetableScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(timetableProvider(studentId));
    final today = DateTime.now().weekday - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: asyncData.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorView(message: 'Could not load timetable', onRetry: () => ref.invalidate(timetableProvider(studentId))),
        data: (timetable) {
          if (timetable == null) {
            return const AppEmptyView(icon: Icons.schedule_outlined, title: 'No timetable published yet', subtitle: "Your school hasn't set up this class's timetable.");
          }
          final periods = (timetable['periods'] as List<dynamic>? ?? []).where((p) => p['day'] == today && p['type'] == 'regular').toList()
            ..sort((a, b) => (a['periodNo'] as num).compareTo(b['periodNo'] as num));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(timetableProvider(studentId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text('${timetable['gradeLevel'] ?? ''} ${timetable['sectionName'] ?? ''} \u2022 Today', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                const SizedBox(height: AppSpacing.md),
                if (periods.isEmpty)
                  const AppEmptyView(icon: Icons.weekend_outlined, title: 'No classes scheduled today')
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
        },
      ),
    );
  }
}
