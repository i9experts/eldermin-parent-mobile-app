import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/models/student.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final resultsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  if (student == null) return [];
  final api = ref.watch(parentApiProvider);
  return api.getResults(student.id);
});

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(selectedStudentProvider);
    final asyncData = ref.watch(resultsProvider);

    if (student == null) return const AppEmptyView(icon: Icons.person_off_outlined, title: 'No child selected');

    return asyncData.when(
      loading: () => const AppLoader(),
      error: (e, _) => AppErrorView(message: 'Could not load results', onRetry: () => ref.invalidate(resultsProvider)),
      data: (reportCards) {
        if (reportCards.isEmpty) {
          return const AppEmptyView(icon: Icons.bar_chart_rounded, title: 'No results published yet', subtitle: "Results will appear here once your child's school publishes them.");
        }
        final latest = reportCards.first;
        final subjects = (latest['subjects'] as List<dynamic>? ?? []);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(resultsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(latest['term'] ?? latest['examType'] ?? 'Latest results', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              const SizedBox(height: AppSpacing.md),
              StatsRow(items: [
                ('${latest['overallPercentage'] ?? '\u2014'}%', 'Overall', null),
                ('${latest['overallGrade'] ?? '\u2014'}', 'Grade', null),
                ('${subjects.length}', 'Subjects', null),
              ]),
              const SizedBox(height: AppSpacing.md),
              const SectionRow(title: 'Subject scores'),
              ...subjects.map((s) {
                final pct = (s['percentage'] as num?)?.round() ?? 0;
                return AppCard(
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: AppColors.pale, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text((s['subject'] ?? '?').toString().substring(0, 1), style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800, fontSize: 11))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.navy)),
                          const SizedBox(height: 4),
                          AppProgressBar(percent: pct, color: pct >= 80 ? AppColors.green : (pct >= 60 ? AppColors.blue : AppColors.amber)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.navy)),
                  ]),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
