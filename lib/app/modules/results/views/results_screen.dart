import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/chart_widgets.dart';
import '../../../../core/widgets/em_tab_heading.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/widgets/tab_state_list.dart';
import '../../students/controllers/student_controller.dart';
import '../controllers/results_controller.dart';

/// Progress tab root (teacher tab-root pattern: [TabHeading] + [TabStateList], teacher `classes_screen.dart:59-72`,
/// `screen_state_view.dart:12-102`). State precedence is unchanged: loading, then error, then locked, then data.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = Get.find<StudentController>();
    final controller = Get.put(ResultsController());

    return Obx(() {
      if (students.selectedStudent == null) {
        return const AppEmptyView(icon: Icons.person_off_outlined, title: 'No child selected');
      }

      const heading = TabHeading(title: 'Learning progress', caption: 'Academic performance and growth');
      final loading = controller.loading.value && controller.reportCards.isEmpty;
      final reportCards = controller.reportCards;
      final TabListState state;
      if (loading) {
        state = TabListState.loading;
      } else if (controller.error.value != null) {
        state = TabListState.error;
      } else if (controller.locked.value) {
        state = TabListState.locked;
      } else if (reportCards.isEmpty) {
        state = TabListState.empty;
      } else {
        state = TabListState.data;
      }

      const skeleton = [
        ShimmerHeroCardSkeleton(),
        SizedBox(height: EmSpacing.s16),
        ShimmerChartSkeleton(),
        SizedBox(height: EmSpacing.s16),
        ShimmerListRowSkeleton(),
        ShimmerListRowSkeleton(),
        ShimmerListRowSkeleton(),
      ];

      if (state != TabListState.data) {
        return TabStateList(
          state: state,
          onRefresh: controller.fetch,
          header: const [heading],
          skeleton: skeleton,
          errorMessage: controller.error.value,
          onRetry: controller.fetch,
          emptyIcon: Icons.bar_chart_rounded,
          emptyTitle: 'No results published yet',
          emptySubtitle: "Results will appear here once your child's school publishes them. Pull down to refresh.",
        );
      }

      final latest = reportCards.first;
      final subjects = (latest['subjects'] as List<dynamic>? ?? []);
      final overallPct = (latest['overallPercentage'] as num?)?.round();

      // reportCards is newest-first from the API; reverse for a
      // chronological trend, and only chart entries with a usable score.
      final chronological = reportCards.reversed.toList();
      final trendPoints = [
        for (final rc in chronological)
          if ((rc['overallPercentage'] as num?) != null)
            (
              (rc['assessmentTitle'] ?? rc['term'] ?? '').toString(),
              (rc['overallPercentage'] as num).toDouble(),
            ),
      ];

      String trendText;
      if (reportCards.length > 1 && overallPct != null) {
        final prevPct = (reportCards[1]['overallPercentage'] as num?)?.round();
        if (prevPct != null) {
          final delta = overallPct - prevPct;
          trendText = delta >= 0 ? '↑ $delta points since last term' : '↓ ${delta.abs()} points since last term';
        } else {
          trendText = 'Latest performance snapshot';
        }
      } else {
        trendText = 'Latest performance snapshot';
      }

      return TabStateList(
        state: state,
        onRefresh: controller.fetch,
        header: [
          heading,
          // the assessment the numbers below are for
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: EmChip.status(label: (latest['assessmentTitle'] ?? latest['term'] ?? 'Latest').toString(), tone: EmTone.info),
            ),
          ),
        ],
        data: [
          HeroCard(
            kicker: 'Overall achievement',
            value: latest['overallGrade']?.toString() ?? (overallPct != null ? '$overallPct%' : '—'),
            trend: trendText,
            percent: overallPct ?? 0,
            metrics: [
              ('${overallPct ?? '—'}%', 'Overall'),
              ('${latest['overallGrade'] ?? '—'}', 'Grade'),
              ('${subjects.length}', 'Subjects'),
            ],
            metricIcons: const [Icons.percent_rounded, Icons.workspace_premium_outlined, Icons.menu_book_rounded],
          ),
          if (trendPoints.length >= 2) ...[
            const SizedBox(height: EmSpacing.s16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Performance trend', style: EmType.label.copyWith(color: EmColors.ink)),
                  const SizedBox(height: EmSpacing.s12),
                  AppLineChart(points: trendPoints),
                ],
              ),
            ),
          ],
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
      );
    });
  }
}
