import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/widgets/tab_state_list.dart';
import '../../students/controllers/student_controller.dart';
import '../controllers/term_report_card_controller.dart';

/// Whole-term report card - a comprehensive summary across every assessment in
/// a term, as opposed to Results (per-exam report cards). Every optional
/// metric/section below (GPA, class position, class average, subject
/// breakdown) is shown only when the field is present: a school's Assessment
/// Master Settings > Parent Visibility controls decide which of these the
/// backend actually sends, so the JSON may simply omit them.
class TermReportCardScreen extends StatelessWidget {
  const TermReportCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = Get.find<StudentController>();
    final controller = Get.put(TermReportCardController());

    return EmScaffold(
      appBar: EmAppBar(title: 'Term Report Card'),
      body: Obx(() {
        if (students.selectedStudent == null) {
          return const AppEmptyView(icon: Icons.person_off_outlined, title: 'No child selected');
        }

        final loading = controller.loading.value && controller.termReportCards.isEmpty;
        final cards = controller.termReportCards;
        final TabListState state;
        if (loading) {
          state = TabListState.loading;
        } else if (controller.error.value != null) {
          state = TabListState.error;
        } else if (controller.locked.value) {
          state = TabListState.locked;
        } else if (cards.isEmpty) {
          state = TabListState.empty;
        } else {
          state = TabListState.data;
        }

        const skeleton = [
          ShimmerHeroCardSkeleton(),
          SizedBox(height: EmSpacing.s16),
          ShimmerListRowSkeleton(),
          ShimmerListRowSkeleton(),
          ShimmerListRowSkeleton(),
        ];

        if (state != TabListState.data) {
          return TabStateList(
            state: state,
            onRefresh: controller.fetch,
            skeleton: skeleton,
            errorMessage: controller.error.value,
            onRetry: controller.fetch,
            emptyIcon: Icons.fact_check_outlined,
            emptyTitle: 'No term report cards published yet',
            emptySubtitle: "Term report cards will appear here once your child's school publishes them. Pull down to refresh.",
          );
        }

        final latest = cards.first;
        final subjects = latest['subjects'] as List<dynamic>?;
        final overallPct = (latest['overallPercentage'] as num?)?.round();
        final overallGrade = latest['overallGrade']?.toString();
        final overallGPA = (latest['overallGPA'] as num?);
        final classPosition = (latest['classPosition'] as num?)?.round();
        final totalStudents = (latest['totalStudents'] as num?)?.round();
        final classAverage = (latest['classAveragePercentage'] as num?)?.round();

        final metrics = <(String, String)>[
          ('${overallPct ?? '—'}%', 'Overall'),
          if (overallGrade != null) (overallGrade, 'Grade'),
          if (overallGPA != null) (overallGPA.toStringAsFixed(1), 'GPA'),
          if (classPosition != null && totalStudents != null) ('$classPosition / $totalStudents', 'Class Rank'),
          if (subjects != null) ('${subjects.length}', 'Subjects'),
        ];
        final metricIcons = <IconData>[
          Icons.percent_rounded,
          if (overallGrade != null) Icons.workspace_premium_outlined,
          if (overallGPA != null) Icons.star_outline_rounded,
          if (classPosition != null && totalStudents != null) Icons.leaderboard_outlined,
          if (subjects != null) Icons.menu_book_rounded,
        ];

        return TabStateList(
          state: state,
          onRefresh: controller.fetch,
          header: [
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: EmChip.status(label: (latest['term'] ?? 'Latest term').toString(), tone: EmTone.info),
              ),
            ),
          ],
          data: [
            HeroCard(
              kicker: 'Term achievement',
              value: overallGrade ?? (overallPct != null ? '$overallPct%' : '—'),
              trend: 'Comprehensive term summary',
              percent: overallPct ?? 0,
              metrics: metrics,
              metricIcons: metricIcons,
            ),
            if (classAverage != null) ...[
              const SizedBox(height: EmSpacing.s12),
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.groups_outlined, color: EmColors.textSecondary, size: 20),
                    const SizedBox(width: EmSpacing.s12),
                    Expanded(child: Text('Class average: $classAverage%', style: EmType.body.copyWith(color: EmColors.ink))),
                  ],
                ),
              ),
            ],
            if (subjects != null) ...[
              const SizedBox(height: EmSpacing.s8),
              const SectionRow(title: 'Subject scores'),
              ...subjects.map((s) {
                final pct = (s['percentage'] as num?)?.round() ?? 0;
                return AppCard(
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: EmColors.primaryTint, shape: BoxShape.circle),
                      child: Center(
                        child: Text((s['subject'] ?? '?').toString().substring(0, 1), style: EmType.label.copyWith(color: EmColors.primary)),
                      ),
                    ),
                    const SizedBox(width: EmSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s['subject'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.body.copyWith(color: EmColors.ink)),
                          const SizedBox(height: EmSpacing.s4),
                          AppProgressBar(percent: pct, color: pct >= 80 ? EmColors.success : (pct >= 60 ? EmColors.primary : EmColors.accent)),
                        ],
                      ),
                    ),
                    const SizedBox(width: EmSpacing.s12),
                    Text('$pct%', maxLines: 1, style: EmType.valueSmall.copyWith(color: EmColors.ink)),
                  ]),
                );
              }),
            ],
            if ((latest['classTeacherRemarks'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: EmSpacing.s8),
              const SectionRow(title: "Class teacher's remarks"),
              AppCard(child: Text(latest['classTeacherRemarks'].toString(), style: EmType.body.copyWith(color: EmColors.ink))),
            ],
          ],
        );
      }),
    );
  }
}
