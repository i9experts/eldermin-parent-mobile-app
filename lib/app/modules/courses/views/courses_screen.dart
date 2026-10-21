import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/courses_controller.dart';

class CoursesScreen extends GetView<CoursesController> {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'My courses', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      body: Obx(() {
        if (controller.loading.value && controller.courses.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(withChip: false),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }
        final courses = controller.courses;
        final done = courses.fold<int>(0, (a, c) => a + ((c['completedLessons'] as num?)?.toInt() ?? 0));
        final total = courses.fold<int>(0, (a, c) => a + ((c['totalLessons'] as num?)?.toInt() ?? 0));

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(title: 'My courses', caption: 'Lessons published by your child\'s teachers'),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${courses.length}', 'Courses', null),
                ('$done/$total', 'Lessons done', null),
              ]),
              const SizedBox(height: AppSpacing.lg),
              if (courses.isEmpty)
                const AppEmptyView(
                  icon: Icons.school_outlined,
                  title: 'No courses yet',
                  subtitle: 'Courses your child\'s teachers publish will appear here.',
                )
              else
                ...courses.map((c) => _CourseCard(course: Map<String, dynamic>.from(c as Map))),
            ],
          ),
        );
      }),
    );
  }
}

class _CourseCard extends GetView<CoursesController> {
  final Map<String, dynamic> course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final syllabusId = course['syllabusId']?.toString() ?? '';
    final pct = (course['completionPct'] as num?)?.toInt() ?? 0;
    final subtitle = [
      if ((course['teacherName']?.toString() ?? '').isNotEmpty) course['teacherName'].toString(),
      if ((course['term']?.toString() ?? '').isNotEmpty) course['term'].toString(),
    ].join(' · ');
    final units = ((course['units'] as List<dynamic>?) ?? []).map((u) => Map<String, dynamic>.from(u as Map));

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: CustomText(
              text: course['subjectName']?.toString() ?? 'Course',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.primaryColor),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle.isNotEmpty)
                  CustomText(text: subtitle, color: AppColors.muted, fontSize: 11),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: AppProgressBar(percent: pct, color: AppColors.blue)),
                  const SizedBox(width: 8),
                  CustomText(text: '$pct%', fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryColor),
                ]),
              ],
            ),
          ),
          children: [
            for (final u in units) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: CustomText(
                      text: 'Unit ${u['unitNo']}: ${u['unitName'] ?? ''}',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.blue),
                ),
              ),
              for (final t in ((u['topics'] as List<dynamic>?) ?? []).map((t) => Map<String, dynamic>.from(t as Map))) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: CustomText(
                        text: t['topicName']?.toString() ?? '',
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: AppColors.ink),
                  ),
                ),
                for (final l in ((t['lessons'] as List<dynamic>?) ?? []).map((l) => Map<String, dynamic>.from(l as Map)))
                  _LessonRow(
                    syllabusId: syllabusId,
                    unitNo: (u['unitNo'] as num).toInt(),
                    topicNo: (t['topicNo'] as num).toInt(),
                    lesson: l,
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonRow extends GetView<CoursesController> {
  final String syllabusId;
  final int unitNo;
  final int topicNo;
  final Map<String, dynamic> lesson;
  const _LessonRow({required this.syllabusId, required this.unitNo, required this.topicNo, required this.lesson});

  String? get _link {
    for (final k in ['url', 'fileUrl']) {
      final v = lesson[k]?.toString() ?? '';
      if (v.startsWith('http')) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lessonNo = (lesson['lessonNo'] as num).toInt();
    final key = CoursesController.lessonKey(syllabusId, unitNo, topicNo, lessonNo);
    final status = lesson['status']?.toString() ?? 'not_started';
    final completed = status == 'completed';
    final link = _link;

    return Obx(() {
      final busy = controller.updatingKey.value == key;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            busy
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    tooltip: completed ? 'Mark as not done' : 'Mark as done',
                    icon: Icon(completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: completed ? AppColors.secondryColor : AppColors.muted),
                    onPressed: () =>
                        controller.setLessonStatus(syllabusId, unitNo, topicNo, lessonNo, completed ? 'not_started' : 'completed'),
                  ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                      text: lesson['title']?.toString() ?? 'Lesson',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                  if ((lesson['description']?.toString() ?? '').isNotEmpty)
                    CustomText(
                        text: lesson['description'].toString(),
                        fontSize: 11,
                        color: AppColors.muted,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  if (status == 'in_progress') const AppTag('In progress', style: TagStyle.amber),
                ],
              ),
            ),
            if (link != null)
              IconButton(
                tooltip: 'Open',
                icon: const Icon(Icons.open_in_new_rounded, color: AppColors.blue, size: 20),
                onPressed: () async {
                  await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
                  if (status == 'not_started') {
                    controller.setLessonStatus(syllabusId, unitNo, topicNo, lessonNo, 'in_progress');
                  }
                },
              ),
          ],
        ),
      );
    });
  }
}
