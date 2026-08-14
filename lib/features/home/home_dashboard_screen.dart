import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/models/student.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/hero_card.dart';
import '../homework/homework_screen.dart';
import '../attendance/attendance_screen.dart';
import '../dues/dues_screen.dart';
import '../timetable/timetable_screen.dart';

final homeAttendanceProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  if (student == null) return [];
  final api = ref.watch(parentApiProvider);
  return api.getAttendance(student.id);
});

final homeHomeworkProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  if (student == null) return [];
  final api = ref.watch(parentApiProvider);
  return api.getHomework(student.id);
});

final homeDuesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  if (student == null) return [];
  final api = ref.watch(parentApiProvider);
  return api.getDues(student.id);
});

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(selectedStudentProvider);
    final attendanceAsync = ref.watch(homeAttendanceProvider);
    final homeworkAsync = ref.watch(homeHomeworkProvider);
    final duesAsync = ref.watch(homeDuesProvider);

    if (student == null) {
      return const AppEmptyView(icon: Icons.person_off_outlined, title: 'No child selected', subtitle: 'Tap the profile at the top to choose a child.');
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(homeAttendanceProvider);
        ref.invalidate(homeHomeworkProvider);
        ref.invalidate(homeDuesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          attendanceAsync.when(
            loading: () => const SizedBox(height: 140, child: AppLoader()),
            error: (e, _) => AppErrorView(message: 'Could not load attendance', onRetry: () => ref.invalidate(homeAttendanceProvider)),
            data: (records) {
              final total = records.length;
              final present = records.where((r) => r['status'] == 'present').length;
              final pct = total == 0 ? 0 : ((present / total) * 100).round();
              return HeroCard(
                kicker: "${student.firstName}'s day at a glance",
                value: total == 0 ? '\u2014' : '$pct%',
                trend: total == 0 ? 'No attendance recorded yet' : (pct >= 90 ? 'Strong attendance this month' : 'Keep an eye on attendance'),
                percent: pct,
                metrics: [
                  (total == 0 ? '\u2014' : '$pct%', 'Attendance'),
                  homeworkAsync.maybeWhen(data: (hw) => ('${hw.length}', 'Homework'), orElse: () => ('\u2014', 'Homework')),
                  duesAsync.maybeWhen(data: (d) => (d.any((x) => (x['balanceDue'] ?? 0) > 0) ? 'Due' : 'Clear', 'Fees'), orElse: () => ('\u2014', 'Fees')),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionRow(title: 'Quick access'),
          _QuickAccessGrid(studentId: student.id),
          const SizedBox(height: AppSpacing.lg),
          SectionRow(title: "Today's priority", onSeeAll: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomeworkScreen(studentId: student.id)))),
          homeworkAsync.when(
            loading: () => const AppLoader(),
            error: (e, _) => const SizedBox.shrink(),
            data: (items) {
              final pending = items.where((h) => h['status'] != 'graded' && h['status'] != 'submitted').take(3).toList();
              if (pending.isEmpty) {
                return const AppEmptyView(icon: Icons.check_circle_outline_rounded, title: 'All caught up', subtitle: 'No pending homework right now.');
              }
              return Column(
                children: pending.map((h) {
                  final due = h['dueDate'] != null ? DateTime.tryParse(h['dueDate'].toString()) : null;
                  return ListCardRow(
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.amber,
                    title: h['subject'] ?? h['title'] ?? 'Homework',
                    subtitle: h['title'] ?? '',
                    trailing: due != null ? AppTag('Due ${due.day}/${due.month}', style: TagStyle.amber) : null,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final String studentId;
  const _QuickAccessGrid({required this.studentId});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.check_circle_outline_rounded, 'Attendance', AppColors.blue, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttendanceScreen(studentId: studentId)))),
      (Icons.menu_book_rounded, 'Homework', AppColors.amber, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomeworkScreen(studentId: studentId)))),
      (Icons.account_balance_wallet_outlined, 'Pay fees', AppColors.green, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DuesScreen(studentId: studentId)))),
      (Icons.schedule_rounded, 'Timetable', AppColors.purple, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TimetableScreen(studentId: studentId)))),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: items.map((item) {
        return GestureDetector(
          onTap: item.$4,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(17)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: item.$3.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(item.$1, color: item.$3, size: 17),
                ),
                const SizedBox(height: 7),
                Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
