import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final attendanceListProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, studentId) async {
  final api = ref.watch(parentApiProvider);
  return api.getAttendance(studentId);
});

class AttendanceScreen extends ConsumerWidget {
  final String studentId;
  const AttendanceScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(attendanceListProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: asyncData.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorView(message: 'Could not load attendance', onRetry: () => ref.invalidate(attendanceListProvider(studentId))),
        data: (records) {
          final total = records.length;
          final present = records.where((r) => r['status'] == 'present').length;
          final absent = records.where((r) => r['status'] == 'absent').length;
          final late = records.where((r) => r['status'] == 'late').length;
          final pct = total == 0 ? 0 : ((present / total) * 100).round();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(attendanceListProvider(studentId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: AppColors.line)),
                  child: Column(children: [
                    Text('$pct%', style: const TextStyle(color: AppColors.green, fontSize: 26, fontWeight: FontWeight.w800)),
                    const Text('Recorded attendance', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ]),
                ),
                const SizedBox(height: AppSpacing.md),
                StatsRow(items: [('$present', 'Present', null), ('$absent', 'Absent', null), ('$late', 'Late', null)]),
                const SizedBox(height: AppSpacing.md),
                if (records.isEmpty)
                  const AppEmptyView(icon: Icons.event_busy_outlined, title: 'No attendance recorded yet')
                else
                  ...records.take(30).map((r) {
                    final date = r['date'] != null ? DateTime.tryParse(r['date'].toString()) : null;
                    final status = r['status'] as String? ?? '';
                    final style = status == 'present' ? TagStyle.green : (status == 'absent' ? TagStyle.red : TagStyle.amber);
                    return AppCard(
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(date != null ? '${date.day}/${date.month}/${date.year}' : '\u2014', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.navy)),
                        AppTag(status.isEmpty ? '\u2014' : status[0].toUpperCase() + status.substring(1), style: style),
                      ]),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
