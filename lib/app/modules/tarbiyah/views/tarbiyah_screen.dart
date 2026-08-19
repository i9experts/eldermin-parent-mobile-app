import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/tarbiyah_controller.dart';

class TarbiyahScreen extends GetView<TarbiyahController> {
  const TarbiyahScreen({super.key});

  String _titleCase(String key) {
    final spaced =
        key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}');
    if (spaced.isEmpty) return spaced;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Growth & tarbiyah',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Obx(() {
        if (controller.loading.value &&
            controller.tarbiyahAssessments.isEmpty &&
            controller.behaviourRecords.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerDateStripSkeleton(),
                const SizedBox(height: AppSpacing.md),
                const ShimmerHeroCardSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.md),
                const ShimmerChartSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final assessment = controller.latestAssessment;
        final records = controller.behaviourRecords;
        final traits = (assessment?['traits'] as List<dynamic>?) ?? [];
        final strengths =
            (assessment?['areasOfStrength'] as List<dynamic>?) ?? [];
        final overallPct = (assessment?['overallPercentage'] as num?)?.round();

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(
                title: 'Growth & tarbiyah',
                caption: 'Character, wellbeing and positive habits',
                selectLabel: 'This month',
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.md),
              if (assessment != null)
                HeroCard(
                  kicker: 'Holistic growth score',
                  value: overallPct != null
                      ? '$overallPct%'
                      : (assessment['overallScore']?.toString() ?? '—'),
                  trend: strengths.isNotEmpty
                      ? strengths.first.toString()
                      : (assessment['teacherObservations']?.toString() ??
                          'Consistent positive development'),
                  percent: overallPct ?? 0,
                  ringColor: AppColors.amber,
                  metrics: [
                    (
                      '${records.where((r) => (r['points'] ?? 0) > 0).length}',
                      'Merits'
                    ),
                    ('${traits.length}', 'Traits tracked'),
                    (
                      '${records.where((r) => (r['points'] ?? 0) < 0).length}',
                      'Concerns'
                    ),
                  ],
                )
              else
                const AppEmptyView(
                    icon: Icons.spa_outlined,
                    title: 'No tarbiyah assessment yet',
                    subtitle:
                        'Character assessments will appear here once recorded.'),
              const SizedBox(height: AppSpacing.lg),
              if (traits.isNotEmpty) ...[
                StatsRow(items: [
                  for (final t in traits.take(3))
                    (
                      '${((Map<String, dynamic>.from(t as Map))['score'] as num?)?.round() ?? 0}%',
                      _titleCase((Map<String, dynamic>.from(t)['traitKey'] ??
                              'Trait')
                          .toString()),
                      null,
                    ),
                ]),
                const SizedBox(height: AppSpacing.md),
                const SectionRow(title: 'Character development'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: traits.asMap().entries.map((e) {
                      final t = Map<String, dynamic>.from(e.value as Map);
                      final score = (t['score'] as num?)?.round() ?? 0;
                      final key = t['traitKey']?.toString() ?? 'Trait';
                      return Padding(
                        padding: EdgeInsets.only(top: e.key == 0 ? 0 : 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: CustomText(
                                      text: _titleCase(key),
                                      color: AppColors.muted,
                                      fontSize: 9.5,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                CustomText(
                                    text: '$score%',
                                    color: AppColors.primaryColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AppProgressBar(
                                percent: score,
                                color: score < 88
                                    ? AppColors.amber
                                    : AppColors.secondryColor),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const SectionRow(title: 'Teacher notes & observations'),
              if (records.isEmpty)
                const AppEmptyView(
                    icon: Icons.favorite_outline_rounded,
                    title: 'No observations recorded yet')
              else
                ...records.map((r) {
                  final rec = Map<String, dynamic>.from(r as Map);
                  final points = (rec['points'] as num?) ?? 0;
                  final positive = points >= 0;
                  return ListCardRow(
                    icon: Icons.favorite_rounded,
                    iconColor: positive ? AppColors.secondryColor : AppColors.red,
                    title: rec['title']?.toString() ??
                        rec['category']?.toString() ??
                        'Observation',
                    subtitle: rec['description']?.toString() ?? '',
                    trailing: AppTag(positive ? 'Merit' : 'Follow-up',
                        style: positive ? TagStyle.green : TagStyle.amber),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
