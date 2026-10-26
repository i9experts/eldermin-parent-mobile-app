import 'package:flutter/material.dart';
import '../../../components/custom_text.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/locked_feature_view.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_button.dart';
import '../controllers/quiz_attempt_controller.dart';

class QuizAttemptScreen extends GetView<QuizAttemptController> {
  const QuizAttemptScreen({super.key});

  Future<bool> _confirmLeave(BuildContext context) async {
    if (controller.result.value != null || controller.answeredCount == 0) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave quiz?'),
        content: const Text('Your answers on this screen will be lost. You can resume the quiz later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave(context)) Get.back();
      },
      child: EmScaffold(
        appBar: EmAppBar(title: controller.title),
        body: Obx(() {
          if (controller.loading.value) return const Center(child: CircularProgressIndicator());
          if (controller.error.value != null) {
            return AppErrorView(message: controller.error.value!, onRetry: controller.start);
          }
          if (controller.locked.value) return const LockedFeatureView();
          if (controller.result.value != null) return _ResultView(result: controller.result.value!);
          return _QuestionView();
        }),
      ),
    );
  }
}

class _QuestionView extends GetView<QuizAttemptController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final qs = controller.questions;
      if (qs.isEmpty) {
        return const AppEmptyView(
            icon: Icons.quiz_outlined, title: 'No questions', subtitle: 'This quiz has no questions yet.');
      }
      final i = controller.currentIndex.value;
      final q = qs[i];
      final id = q['_id'].toString();
      final type = q['type']?.toString() ?? '';
      final options = ((q['options'] as List<dynamic>?) ?? []).map((o) => (o as Map)['text']?.toString() ?? '').toList();
      final selected = controller.answers[id];
      final isLast = i == qs.length - 1;

      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(children: [
                  CustomText(
                      text: 'Question ${i + 1} of ${qs.length}',
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                  const Spacer(),
                  AppTag('${q['marks'] ?? ''} marks'),
                ]),
                const SizedBox(height: 6),
                AppProgressBar(percent: ((i + 1) * 100 / qs.length).round(), color: AppColors.blue),
                const SizedBox(height: AppSpacing.md),
                CustomText(
                    text: q['questionText']?.toString() ?? '',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
                if ((q['questionImage']?.toString() ?? '').startsWith('http')) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(q['questionImage'].toString(), errorBuilder: (_, __, ___) => const SizedBox.shrink())),
                ],
                const SizedBox(height: AppSpacing.md),
                if (type == 'mcq')
                  for (var o = 0; o < options.length; o++)
                    AppCard(
                      onTap: () => controller.selectOption(id, o),
                      child: Row(children: [
                        Icon(selected?['selectedOptionIndex'] == o ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: selected?['selectedOptionIndex'] == o ? AppColors.blue : AppColors.muted),
                        const SizedBox(width: 10),
                        Expanded(child: CustomText(text: options[o], fontSize: 13, color: AppColors.ink)),
                      ]),
                    )
                else if (type == 'true_false')
                  for (final v in const ['True', 'False'])
                    AppCard(
                      onTap: () => controller.setText(id, v),
                      child: Row(children: [
                        Icon(selected?['textAnswer'] == v ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: selected?['textAnswer'] == v ? AppColors.blue : AppColors.muted),
                        const SizedBox(width: 10),
                        CustomText(text: v, fontSize: 13, color: AppColors.ink),
                      ]),
                    )
                else
                  TextFormField(
                    key: ValueKey(id),
                    initialValue: selected?['textAnswer']?.toString() ?? '',
                    maxLines: 6,
                    onChanged: (t) => controller.setText(id, t),
                    decoration: InputDecoration(
                      hintText: 'Type your answer',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 12),
              child: Row(children: [
                if (i > 0)
                  Expanded(
                      child: CustomButton(
                          label: 'Previous',
                          height: 46,
                          color: AppColors.muted,
                          onPressed: () => controller.goTo(i - 1))),
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: isLast
                      ? CustomButton(
                          label: controller.submitting.value ? '' : 'Submit (${controller.answeredCount}/${qs.length})',
                          height: 46,
                          color: AppColors.primaryColor,
                          enabled: !controller.submitting.value,
                          prefix: controller.submitting.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : null,
                          onPressed: () => _confirmSubmit(context),
                        )
                      : CustomButton(
                          label: 'Next', height: 46, color: AppColors.primaryColor, onPressed: () => controller.goTo(i + 1)),
                ),
              ]),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _confirmSubmit(BuildContext context) async {
    final unanswered = controller.questions.length - controller.answeredCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit quiz?'),
        content: Text(unanswered > 0
            ? '$unanswered question(s) are unanswered and will score 0. You cannot change answers after submitting.'
            : 'You cannot change answers after submitting.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Review')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true) return;
    final err = await controller.submit();
    if (err != null) CustomAppSnackbar.error(err);
  }
}

class _ResultView extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final graded = result['status'] == 'graded';
    final total = result['totalMarks'];
    final passing = result['passingMarks'];
    final obtained = result['obtainedMarks'];
    final passed = graded && obtained is num && passing is num && obtained >= passing;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: 40),
        Icon(graded ? (passed ? Icons.emoji_events_rounded : Icons.flag_outlined) : Icons.hourglass_top_rounded,
            size: 64, color: graded ? (passed ? AppColors.secondryColor : AppColors.amber) : AppColors.blue),
        const SizedBox(height: 16),
        Center(
          child: CustomText(
              text: graded ? '$obtained / $total' : 'Quiz submitted',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor),
        ),
        const SizedBox(height: 8),
        Center(
          child: CustomText(
              text: graded
                  ? (passed ? 'Well done - you passed!' : 'Passing marks are $passing. Keep practising!')
                  : 'Some answers need your teacher to mark them. Your score will appear in the quiz list once they do.',
              color: AppColors.muted,
              fontSize: 13,
              textAlign: TextAlign.center),
        ),
        if (!graded && result['autoGradedMarks'] != null) ...[
          const SizedBox(height: 8),
          Center(
              child: CustomText(
                  text: 'Auto-marked so far: ${result['autoGradedMarks']}', color: AppColors.muted, fontSize: 12)),
        ],
        const SizedBox(height: 32),
        CustomButton(label: 'Back to quizzes', height: 48, color: AppColors.primaryColor, onPressed: () => Get.back()),
      ],
    );
  }
}
