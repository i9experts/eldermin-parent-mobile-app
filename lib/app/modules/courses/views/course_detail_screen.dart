import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_text.dart';
import '../controllers/course_detail_controller.dart';

const Map<String, IconData> _kLessonTypeIcon = {
  'video': Icons.play_circle_outline_rounded,
  'document': Icons.description_outlined,
  'reading': Icons.menu_book_outlined,
  'link': Icons.link_rounded,
};

class CourseDetailScreen extends GetView<CourseDetailController> {
  const CourseDetailScreen({super.key});

  Future<void> _openLesson(BuildContext context, Map lesson, int unitNo, int topicNo) async {
    final link = (lesson['url'] ?? lesson['fileUrl'])?.toString();
    if (link == null || link.isEmpty) {
      CustomAppSnackbar.warning('This lesson has no link attached.');
      return;
    }
    final uri = Uri.tryParse(link);
    if (uri == null || !await canLaunchUrl(uri)) {
      CustomAppSnackbar.error('Could not open this link.');
      return;
    }
    // Opening the lesson is a reasonable signal the student has started it
    // - auto-marks in_progress on first open, never overwrites an already
    // completed lesson (re-opening a finished video shouldn't un-complete it).
    if (lesson['status'] == 'not_started') {
      controller.setLessonStatus(unitNo, topicNo, lesson['lessonNo'] as int, 'in_progress');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Reading `version` ties this Obx to every local mutation even
      // though `course` itself is a plain Map, not an Rx value.
      // ignore: unused_local_variable
      final _ = controller.version.value;
      final course = controller.course;
      final pct = (course['completionPct'] ?? 0) as int;
      final total = (course['totalLessons'] ?? 0) as int;
      final done = (course['completedLessons'] ?? 0) as int;
      final units = (course['units'] as List?) ?? [];

      return Scaffold(
        appBar: AppBar(
          title: CustomText(
              text: course['subjectName']?.toString() ?? 'Course',
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DonutRing(percent: pct, color: pct >= 100 ? AppColors.green : AppColors.blue, size: 68),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((course['teacherName'] ?? '').toString().isNotEmpty)
                          CustomText(
                              text: course['teacherName'].toString(),
                              color: AppColors.muted,
                              fontSize: 10.5,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        CustomText(
                            text: '$done of $total lessons completed',
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryColor,
                            fontSize: 12.5),
                        if (pct >= 100) ...[
                          const SizedBox(height: 6),
                          const AppTag('Course completed', style: TagStyle.green),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (units.isEmpty)
              const AppEmptyView(
                  icon: Icons.menu_book_outlined, title: 'No lessons in this course yet')
            else
              ...units.map((u) {
                final unit = Map<String, dynamic>.from(u as Map);
                final unitNo = unit['unitNo'] as int;
                final topics = (unit['topics'] as List?) ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionRow(title: unit['unitName']?.toString() ?? 'Unit $unitNo'),
                    ...topics.map((t) {
                      final topic = Map<String, dynamic>.from(t as Map);
                      final topicNo = topic['topicNo'] as int;
                      final lessons = (topic['lessons'] as List?) ?? [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 2, bottom: 6),
                              child: CustomText(
                                  text: topic['topicName']?.toString() ?? 'Topic $topicNo',
                                  color: AppColors.muted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700),
                            ),
                            ...lessons.map((l) {
                              final lesson = Map<String, dynamic>.from(l as Map);
                              final lessonNo = lesson['lessonNo'] as int;
                              final status = lesson['status']?.toString() ?? 'not_started';
                              final complete = status == 'completed';
                              final key = '$unitNo-$topicNo-$lessonNo';
                              return Obx(() {
                                final saving = controller.savingKey.value == key;
                                return AppCard(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: saving
                                            ? null
                                            : () => controller.setLessonStatus(
                                                unitNo, topicNo, lessonNo,
                                                complete ? 'not_started' : 'completed'),
                                        child: saving
                                            ? const SizedBox(
                                                width: 22, height: 22,
                                                child: Padding(
                                                  padding: EdgeInsets.all(2),
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              )
                                            : Icon(
                                                complete
                                                    ? Icons.check_circle_rounded
                                                    : Icons.radio_button_unchecked_rounded,
                                                color: complete ? AppColors.green : AppColors.faint,
                                                size: 22,
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                          _kLessonTypeIcon[lesson['type']] ?? Icons.link_rounded,
                                          color: AppColors.blue, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                                text: lesson['title']?.toString() ?? 'Lesson',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                                color: AppColors.ink,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                            if ((lesson['description'] ?? '').toString().isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              CustomText(
                                                  text: lesson['description'].toString(),
                                                  color: AppColors.muted,
                                                  fontSize: 9.5,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis),
                                            ],
                                            const SizedBox(height: 8),
                                            InkWell(
                                              onTap: () => _openLesson(context, lesson, unitNo, topicNo),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.blue),
                                                  SizedBox(width: 4),
                                                  CustomText(
                                                      text: 'Open lesson',
                                                      color: AppColors.blue,
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w700),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (status == 'in_progress' && !complete)
                                        const AppTag('In progress', style: TagStyle.amber),
                                    ],
                                  ),
                                );
                              });
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }),
          ],
        ),
      );
    });
  }
}
