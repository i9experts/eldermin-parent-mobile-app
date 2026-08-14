import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final homeworkListProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, studentId) async {
  final api = ref.watch(parentApiProvider);
  return api.getHomework(studentId);
});

class HomeworkScreen extends ConsumerStatefulWidget {
  final String studentId;
  const HomeworkScreen({super.key, required this.studentId});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(homeworkListProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Homework')),
      body: asyncData.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorView(message: 'Could not load homework', onRetry: () => ref.invalidate(homeworkListProvider(widget.studentId))),
        data: (items) {
          final filtered = items.where((h) {
            if (_filter == 1) return h['status'] != 'graded' && h['status'] != 'submitted';
            if (_filter == 2) return h['status'] == 'submitted' || h['status'] == 'graded';
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(homeworkListProvider(widget.studentId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                StatsRow(items: [
                  ('${items.length}', 'Assigned', null),
                  ('${items.where((h) => h['status'] == 'submitted' || h['status'] == 'graded').length}', 'Completed', null),
                  ('${items.where((h) => h['status'] != 'graded' && h['status'] != 'submitted').length}', 'Pending', null),
                ]),
                const SizedBox(height: AppSpacing.md),
                SegmentedControl(options: const ['All tasks', 'Pending', 'Submitted'], selectedIndex: _filter, onChanged: (i) => setState(() => _filter = i)),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  const AppEmptyView(icon: Icons.assignment_turned_in_outlined, title: 'Nothing here', subtitle: 'No homework matches this filter.')
                else
                  ...filtered.map((h) {
                    final due = h['dueDate'] != null ? DateTime.tryParse(h['dueDate'].toString()) : null;
                    final isSubmitted = h['status'] == 'submitted' || h['status'] == 'graded';
                    final isOverdue = !isSubmitted && due != null && due.isBefore(DateTime.now());
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(h['subject'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 12))),
                            AppTag(
                              isSubmitted ? 'Submitted' : (isOverdue ? 'Overdue' : (due != null ? 'Due ${due.day}/${due.month}' : 'Pending')),
                              style: isSubmitted ? TagStyle.green : (isOverdue ? TagStyle.red : TagStyle.amber),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text(h['title'] ?? h['description'] ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 10.5)),
                          const SizedBox(height: 10),
                          AppProgressBar(percent: isSubmitted ? 100 : (isOverdue ? 20 : 60), color: isSubmitted ? AppColors.green : (isOverdue ? AppColors.red : AppColors.amber)),
                        ],
                      ),
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
