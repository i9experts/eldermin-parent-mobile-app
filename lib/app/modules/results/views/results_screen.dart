import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/chart_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../../students/controllers/student_controller.dart';
import '../controllers/results_controller.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = Get.find<StudentController>();
    final controller = Get.put(ResultsController());

    return Obx(() {
      if (students.selectedStudent == null)
        return const AppEmptyView(
            icon: Icons.person_off_outlined, title: 'No child selected');
      if (controller.loading.value && controller.reportCards.isEmpty) {
        return AppShimmer(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ShimmerScreenHeaderSkeleton(),
              const SizedBox(height: AppSpacing.lg),
              const ShimmerDateStripSkeleton(),
              const SizedBox(height: AppSpacing.lg),
              const ShimmerHeroCardSkeleton(),
              const SizedBox(height: AppSpacing.md),
              const ShimmerStatsRowSkeleton(count: 3),
              const SizedBox(height: AppSpacing.md),
              const ShimmerChartSkeleton(),
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

      final reportCards = controller.reportCards;
      if (reportCards.isEmpty) {
        return const AppEmptyView(
            icon: Icons.bar_chart_rounded,
            title: 'No results published yet',
            subtitle:
                "Results will appear here once your child's school publishes them.");
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
              (rc['term'] ?? rc['examType'] ?? '').toString(),
              (rc['overallPercentage'] as num).toDouble(),
            ),
      ];

      String trendText;
      if (reportCards.length > 1 && overallPct != null) {
        final prevPct = (reportCards[1]['overallPercentage'] as num?)?.round();
        if (prevPct != null) {
          final delta = overallPct - prevPct;
          trendText = delta >= 0
              ? '↑ $delta points since last term'
              : '↓ ${delta.abs()} points since last term';
        } else {
          trendText = 'Latest performance snapshot';
        }
      } else {
        trendText = 'Latest performance snapshot';
      }

      return RefreshIndicator(
        onRefresh: controller.fetch,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            ScreenHeader(
              title: 'Learning progress',
              caption: 'Academic performance and growth',
              selectLabel:
                  (latest['term'] ?? latest['examType'] ?? 'Latest')
                      .toString(),
            ),
            const AppWeekDateStrip(),
            const SizedBox(height: AppSpacing.lg),
            HeroCard(
              kicker: 'Overall achievement',
              value: latest['overallGrade']?.toString() ??
                  (overallPct != null ? '$overallPct%' : '—'),
              trend: trendText,
              percent: overallPct ?? 0,
              metrics: [
                ('${overallPct ?? '—'}%', 'Overall'),
                ('${latest['overallGrade'] ?? '—'}', 'Grade'),
                ('${subjects.length}', 'Subjects'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            StatsRow(items: [
              ('${latest['overallPercentage'] ?? '—'}%', 'Overall', null),
              ('${latest['overallGrade'] ?? '—'}', 'Grade', null),
              ('${subjects.length}', 'Subjects', null),
            ]),
            if (trendPoints.length >= 2) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                        text: 'Performance trend',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.primaryColor),
                    const SizedBox(height: 10),
                    AppLineChart(points: trendPoints),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const SectionRow(title: 'Subject scores'),
            ...subjects.map((s) {
              final pct = (s['percentage'] as num?)?.round() ?? 0;
              return AppCard(
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: AppColors.pale,
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: CustomText(
                            text: (s['subject'] ?? '?')
                                .toString()
                                .substring(0, 1),
                            color: AppColors.blue,
                            fontWeight: FontWeight.w800,
                            fontSize: 11)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                            text: s['subject'] ?? '',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.primaryColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        AppProgressBar(
                            percent: pct,
                            color: pct >= 80
                                ? AppColors.secondryColor
                                : (pct >= 60
                                    ? AppColors.blue
                                    : AppColors.amber)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  CustomText(
                      text: '$pct%',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.primaryColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
              );
            }),
          ],
        ),
      );
    });
  }
}
