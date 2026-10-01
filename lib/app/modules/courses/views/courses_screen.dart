import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../../../routes/app_routes.dart';
import '../controllers/courses_controller.dart';

class CoursesScreen extends GetView<CoursesController> {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'My Courses',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      body: Obx(() {
        if (controller.loading.value && controller.courses.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.lg),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }

        final courses = controller.courses;
        final completedCourses =
            courses.where((c) => (c['completionPct'] ?? 0) >= 100).length;
        final totalLessons = courses.fold<int>(
            0, (sum, c) => sum + ((c['totalLessons'] ?? 0) as int));
        final completedLessons = courses.fold<int>(
            0, (sum, c) => sum + ((c['completedLessons'] ?? 0) as int));

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(
                title: 'My Courses',
                caption: 'Lessons published by your teachers',
              ),
              if (courses.isNotEmpty) ...[
                StatsRow(items: [
                  ('${courses.length}', 'Courses', null),
                  ('$completedCourses', 'Completed', null),
                  ('$completedLessons/$totalLessons', 'Lessons done', null),
                ]),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SectionRow(title: 'Published courses'),
              if (courses.isEmpty)
                const AppEmptyView(
                  icon: Icons.menu_book_outlined,
                  title: 'No courses published yet',
                  subtitle: 'Your teachers haven\'t published any course lessons for this grade/section yet.',
                )
              else
                ...courses.map((raw) {
                  final c = Map<String, dynamic>.from(raw as Map);
                  final pct = (c['completionPct'] ?? 0) as int;
                  final total = (c['totalLessons'] ?? 0) as int;
                  final done = (c['completedLessons'] ?? 0) as int;
                  final complete = pct >= 100;
                  return AppCard(
                    onTap: () => Get.toNamed(Routes.courseDetail, arguments: {'course': c}),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomText(
                                        text: c['subjectName']?.toString() ?? 'Course',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: AppColors.primaryColor,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  if (complete) const AppTag('Completed', style: TagStyle.green),
                                ],
                              ),
                              if ((c['teacherName'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                CustomText(
                                    text: c['teacherName'].toString(),
                                    color: AppColors.muted,
                                    fontSize: 10,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: AppProgressBar(
                                      percent: pct,
                                      color: complete ? AppColors.green : AppColors.blue)),
                                  const SizedBox(width: 8),
                                  CustomText(
                                      text: '$done/$total',
                                      color: AppColors.muted,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
