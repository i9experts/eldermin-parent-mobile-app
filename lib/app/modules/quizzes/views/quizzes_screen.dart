import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/locked_feature_view.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../routes/app_routes.dart';
import '../controllers/quizzes_controller.dart';

class QuizzesScreen extends GetView<QuizzesController> {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Online quizzes'),
      body: Obx(() {
        if (controller.loading.value && controller.quizzes.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(withChip: false),
                const SizedBox(height: EmSpacing.s12),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }
        if (controller.locked.value) {
          return const LockedFeatureView();
        }
        final quizzes = controller.quizzes;
        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              const ScreenIntro(caption: 'Self-paced quizzes set by your child\'s school'),
              const SizedBox(height: EmSpacing.s16),
              if (quizzes.isEmpty)
                const AppEmptyView(
                  icon: Icons.quiz_outlined,
                  title: 'No quizzes available',
                  subtitle: 'Online quizzes will appear here when your child\'s school sets them.',
                )
              else
                ...quizzes.map((raw) {
                  final q = Map<String, dynamic>.from(raw as Map);
                  final used = (q['attemptsUsed'] as num?)?.toInt() ?? 0;
                  final allowed = (q['attemptsAllowed'] as num?)?.toInt() ?? 1;
                  final latest = q['latestAttempt'] is Map ? Map<String, dynamic>.from(q['latestAttempt'] as Map) : null;
                  final status = latest?['status']?.toString();
                  final inProgress = status == 'in_progress';
                  final canStart = inProgress || used < allowed;

                  String tag;
                  TagStyle style;
                  if (inProgress) {
                    tag = 'In progress';
                    style = TagStyle.amber;
                  } else if (status == 'graded') {
                    tag = '${latest!['obtainedMarks']}/${q['totalMarks']}';
                    style = TagStyle.green;
                  } else if (status == 'submitted') {
                    tag = 'Awaiting marks';
                    style = TagStyle.info;
                  } else {
                    tag = 'Not started';
                    style = TagStyle.neutral;
                  }

                  return ListCardRow(
                    icon: Icons.quiz_outlined,
                    iconColor: AppColors.blue,
                    title: '${q['subject']} - ${q['assessmentTitle'] ?? 'Quiz'}',
                    subtitle: 'Total ${q['totalMarks']} · Pass ${q['passingMarks']} · Attempts $used/$allowed',
                    trailing: AppTag(tag, style: style),
                    onTap: canStart
                        ? () async {
                            await Get.toNamed(Routes.quizAttempt, arguments: {
                              'assessmentId': q['assessmentId'].toString(),
                              'subject': q['subject'].toString(),
                              'title': '${q['subject']} - ${q['assessmentTitle'] ?? 'Quiz'}',
                            });
                            controller.fetch();
                          }
                        : null,
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
