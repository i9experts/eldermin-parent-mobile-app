import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text.dart';
import '../../../components/custom_text_field.dart';
import '../controllers/quiz_attempt_controller.dart';

const _kObjectiveTypes = {'mcq', 'true_false'};

class QuizAttemptScreen extends GetView<QuizAttemptController> {
  const QuizAttemptScreen({super.key});

  Future<bool> _confirmLeave() async {
    if (controller.answeredCount == 0) return true;
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const CustomText(text: 'Leave quiz?', fontWeight: FontWeight.w700),
        content: const CustomText(
            text: 'Your answers so far are saved, and you can resume this attempt later.',
            color: AppColors.muted,
            fontSize: 12.5),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const CustomText(text: 'Stay')),
          TextButton(onPressed: () => Get.back(result: true), child: const CustomText(text: 'Leave', color: AppColors.red)),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmSubmit(BuildContext context) async {
    final total = controller.questions.length;
    final answered = controller.answeredCount;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const CustomText(text: 'Submit quiz?', fontWeight: FontWeight.w700),
        content: CustomText(
            text: answered < total
                ? 'You\'ve answered $answered of $total questions. Unanswered questions will be scored as incorrect. Submit anyway?'
                : 'You\'ve answered all $total questions. This cannot be undone.',
            color: AppColors.muted,
            fontSize: 12.5),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const CustomText(text: 'Review again')),
          TextButton(onPressed: () => Get.back(result: true), child: const CustomText(text: 'Submit', color: AppColors.blue)),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await controller.submit();
    if (!ok) return;
    final result = controller.result.value;
    final status = result?['status']?.toString();
    final obtained = result?['obtainedMarks'];
    final total2 = result?['totalMarks'];
    await Get.dialog(
      AlertDialog(
        title: CustomText(
            text: status == 'graded' ? 'Quiz graded' : 'Quiz submitted',
            fontWeight: FontWeight.w700),
        content: CustomText(
            text: status == 'graded'
                ? 'You scored $obtained out of $total2.'
                : 'Submitted! Some answers need your teacher\'s review before a final score shows.',
            color: AppColors.muted,
            fontSize: 12.5),
        actions: [
          TextButton(
              onPressed: () {
                Get.back(); // close dialog
                Get.back(); // leave the attempt screen
              },
              child: const CustomText(text: 'Done')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // `onPopInvoked(bool)`, not the newer `onPopInvokedWithResult` - kept
      // to the widest-compatible PopScope signature since this repo's
      // exact Flutter version isn't pinned to a minimum here.
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _confirmLeave()) Get.back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: CustomText(
              text: controller.assessmentTitle,
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        body: Obx(() {
          if (controller.loading.value) return const AppLoader();
          if (controller.error.value != null && controller.questions.isEmpty) {
            return AppErrorView(message: controller.error.value!, onRetry: () => Get.back());
          }
          if (controller.questions.isEmpty) {
            return const AppEmptyView(
                icon: Icons.quiz_outlined, title: 'No questions in this quiz');
          }

          final total = controller.questions.length;
          final index = controller.currentIndex.value;
          final q = controller.currentQuestion;
          final qid = q['_id'].toString();
          final type = q['type']?.toString() ?? 'mcq';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                            text: 'Question ${index + 1} of $total',
                            color: AppColors.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700),
                        CustomText(
                            text: '${controller.answeredCount}/$total answered',
                            color: AppColors.blue,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AppProgressBar(percent: ((index + 1) / total * 100).round(), color: AppColors.blue),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppTag('${q['marks'] ?? 1} mark${(q['marks'] ?? 1) == 1 ? '' : 's'}'),
                              const Spacer(),
                              if (!_kObjectiveTypes.contains(type))
                                const AppTag('Manually reviewed', style: TagStyle.amber),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomText(
                              text: q['questionText']?.toString() ?? '',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.ink),
                          const SizedBox(height: 16),
                          _AnswerInput(controller: controller, question: q, qid: qid, type: type),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const SectionRow(title: 'Jump to question'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(total, (i) {
                        final qi = Map<String, dynamic>.from(controller.questions[i] as Map);
                        final answered = controller.isAnswered(qi['_id'].toString());
                        final current = i == index;
                        return InkWell(
                          onTap: () => controller.jumpTo(i),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: current
                                  ? AppColors.primaryColor
                                  : (answered ? AppColors.greenBg : AppColors.background),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: current ? AppColors.primaryColor : AppColors.line),
                            ),
                            child: CustomText(
                                text: '${i + 1}',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: current
                                    ? Colors.white
                                    : (answered ? AppColors.greenText : AppColors.muted)),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (!controller.isFirst)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.previous,
                            child: const CustomText(text: 'Previous'),
                          ),
                        ),
                      if (!controller.isFirst) const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: controller.isLast
                            ? Obx(() => CustomButton(
                                  label: controller.submitting.value ? 'Submitting…' : 'Submit quiz',
                                  color: AppColors.secondryColor,
                                  enabled: !controller.submitting.value,
                                  onPressed: () => _confirmSubmit(context),
                                ))
                            : CustomButton(label: 'Next', onPressed: controller.next),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AnswerInput extends StatelessWidget {
  final QuizAttemptController controller;
  final Map<String, dynamic> question;
  final String qid;
  final String type;
  const _AnswerInput({required this.controller, required this.question, required this.qid, required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == 'mcq') {
      final options = (question['options'] as List?) ?? [];
      return Obx(() {
        final selected = controller.answers[qid]?['selectedOptionIndex'] as int?;
        return Column(
          children: List.generate(options.length, (i) {
            final opt = Map<String, dynamic>.from(options[i] as Map);
            final isSelected = selected == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => controller.selectOption(qid, i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.pale : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.blue : AppColors.line, width: isSelected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? AppColors.blue : AppColors.faint,
                          size: 19),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomText(
                            text: opt['text']?.toString() ?? '',
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primaryColor : AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      });
    }

    if (type == 'true_false') {
      return Obx(() {
        final selected = controller.answers[qid]?['textAnswer'] as String?;
        return Row(
          children: ['True', 'False'].map((v) {
            final isSelected = selected == v;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: v == 'True' ? 8 : 0),
                child: InkWell(
                  onTap: () => controller.selectTrueFalse(qid, v),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.pale : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.blue : AppColors.line, width: isSelected ? 1.5 : 1),
                    ),
                    child: CustomText(
                        text: v,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.primaryColor : AppColors.muted),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      });
    }

    // short / long / fill_blank / matching - free text, manually reviewed.
    return CustomTextField(
      hintText: type == 'long' ? 'Write your answer…' : 'Your answer…',
      maxLines: type == 'long' ? 5 : 1,
      onChanged: (v) => controller.setTextAnswer(qid, v),
    );
  }
}
