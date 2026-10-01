import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text.dart';
import '../../../routes/app_routes.dart';
import '../controllers/quizzes_controller.dart';

class QuizzesScreen extends GetView<QuizzesController> {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'My Quizzes',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      body: Obx(() {
        if (controller.loading.value && controller.quizzes.isEmpty) {
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

        final quizzes = controller.quizzes;
        final graded = quizzes.where((q) => q['latestAttempt']?['status'] == 'graded').length;
        final pendingReview =
            quizzes.where((q) => q['latestAttempt']?['status'] == 'submitted').length;
        final notStarted = quizzes.where((q) => q['latestAttempt'] == null).length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(
                title: 'My Quizzes',
                caption: 'Self-paced online quizzes for your class',
              ),
              if (quizzes.isNotEmpty) ...[
                StatsRow(items: [
                  ('${quizzes.length}', 'Available', null),
                  ('$notStarted', 'Not started', null),
                  ('$graded', 'Graded', null),
                ]),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SectionRow(title: 'Quizzes'),
              if (quizzes.isEmpty)
                const AppEmptyView(
                  icon: Icons.quiz_outlined,
                  title: 'No quizzes available yet',
                  subtitle: 'Your teachers haven\'t assigned any online quizzes to your class yet.',
                )
              else
                ...quizzes.map((raw) {
                  final q = Map<String, dynamic>.from(raw as Map);
                  final attempt = q['latestAttempt'] as Map?;
                  final status = attempt?['status']?.toString();
                  final attemptsUsed = (q['attemptsUsed'] ?? 0) as int;
                  final attemptsAllowed = (q['attemptsAllowed'] ?? 1) as int;
                  final canAttempt = attemptsUsed < attemptsAllowed || status == 'in_progress';

                  TagStyle tagStyle = TagStyle.info;
                  String tagLabel = 'Not started';
                  if (status == 'in_progress') {
                    tagStyle = TagStyle.amber;
                    tagLabel = 'In progress';
                  } else if (status == 'submitted') {
                    tagStyle = TagStyle.amber;
                    tagLabel = 'Pending review';
                  } else if (status == 'graded') {
                    tagStyle = TagStyle.green;
                    final obtained = attempt?['obtainedMarks'];
                    tagLabel = obtained != null ? '$obtained/${q['totalMarks']}' : 'Graded';
                  }

                  String buttonLabel = 'Start quiz';
                  if (status == 'in_progress') buttonLabel = 'Resume';
                  if ((status == 'submitted' || status == 'graded') && canAttempt) {
                    buttonLabel = 'Retake';
                  }

                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                  text: q['subject']?.toString() ?? 'Quiz',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: AppColors.primaryColor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            AppTag(tagLabel, style: tagStyle),
                          ],
                        ),
                        const SizedBox(height: 3),
                        CustomText(
                            text: q['assessmentTitle']?.toString() ?? '',
                            color: AppColors.muted,
                            fontSize: 10.5,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        CustomText(
                            text:
                                '${q['totalMarks'] ?? '—'} marks · $attemptsUsed of $attemptsAllowed attempt${attemptsAllowed == 1 ? '' : 's'} used',
                            color: AppColors.faint,
                            fontSize: 9.5),
                        if (status == 'submitted') ...[
                          const SizedBox(height: 6),
                          const CustomText(
                              text: 'Submitted — some answers are awaiting your teacher\'s review.',
                              color: AppColors.amberText,
                              fontSize: 9.5),
                        ],
                        if (canAttempt && status != 'submitted') ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              label: buttonLabel,
                              height: 38,
                              fontSize: 11.5,
                              onPressed: () => Get.toNamed(Routes.quizAttempt, arguments: {
                                'assessmentId': q['assessmentId']?.toString(),
                                'subject': q['subject']?.toString(),
                                'assessmentTitle': q['assessmentTitle']?.toString(),
                              }),
                            ),
                          ),
                        ],
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
