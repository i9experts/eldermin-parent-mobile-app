import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_bottom_sheet.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text_field.dart';
import '../controllers/homework_controller.dart';

class HomeworkScreen extends GetView<HomeworkController> {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Homework'),
      body: Obx(() {
        if (controller.loading.value && controller.items.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerDateStripSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.md),
                const ShimmerChartSkeleton(),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(5),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final items = controller.items;
        final filtered = controller.filtered;
        final completedCount = items
            .where((h) => ['submitted', 'late', 'graded'].contains((h['mySubmission'] is Map ? h['mySubmission']['status'] : null)))
            .length;
        final pendingCount = items.length - completedCount;
        final completionPct =
            items.isEmpty ? 0 : ((completedCount / items.length) * 100).round();

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ScreenHeader(
                title: 'Homework',
                caption: 'Tasks, submissions and feedback',
                selectLabel:
                    DateFormat('MMMM yyyy').format(controller.selectedMonth.value),
                onSelectTap: () async {
                  final picked = await showAppMonthPicker(
                    context,
                    initialMonth: controller.selectedMonth.value,
                  );
                  if (picked != null) controller.changeMonth(picked);
                },
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${items.length}', 'Assigned', null),
                ('$completedCount', 'Completed', null),
                ('$pendingCount', 'Pending', null),
              ]),
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DonutRing(percent: completionPct, color: AppColors.blue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomText(
                                text: 'Weekly completion',
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.primaryColor),
                            const SizedBox(height: 10),
                            _LegendRow(
                                color: AppColors.secondryColor,
                                label: 'Submitted',
                                value: '$completedCount'),
                            const SizedBox(height: 6),
                            _LegendRow(
                                color: AppColors.amber,
                                label: 'Pending',
                                value: '$pendingCount'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SegmentedControl(
                  options: const ['All tasks', 'Pending', 'Submitted'],
                  selectedIndex: controller.filter.value,
                  onChanged: controller.changeFilter),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
                const AppEmptyView(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Nothing here',
                    subtitle: 'No homework matches this filter.')
              else
                ...filtered.map((h) {
                  final due = h['dueDate'] != null
                      ? DateTime.tryParse(h['dueDate'].toString())
                      : null;
                  final isSubmitted =
                      ['submitted', 'late', 'graded'].contains((h['mySubmission'] is Map ? h['mySubmission']['status'] : null));
                  final isOverdue = !isSubmitted &&
                      due != null &&
                      due.isBefore(DateTime.now());
                  final sub = h['mySubmission'] is Map ? Map<String, dynamic>.from(h['mySubmission'] as Map) : null;
                  final subStatus = sub?['status']?.toString();
                  final graded = subStatus == 'graded';
                  final canSubmit = sub != null && !graded;
                  return AppCard(
                    onTap: () => _openDetail(context, Map<String, dynamic>.from(h as Map)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: CustomText(
                                  text: h['subject'] ?? 'Subject',
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryColor,
                                  fontSize: 12,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          AppTag(
                            isSubmitted
                                ? 'Submitted'
                                : (isOverdue
                                    ? 'Overdue'
                                    : (due != null
                                        ? 'Due ${due.day}/${due.month}'
                                        : 'Pending')),
                            style: isSubmitted
                                ? TagStyle.green
                                : (isOverdue ? TagStyle.red : TagStyle.amber),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        CustomText(
                            text: h['title'] ?? h['description'] ?? '',
                            color: AppColors.muted,
                            fontSize: 10.5,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        if (graded && sub?['grade'] != null) ...[
                          CustomText(
                              text: 'Score: ${sub!['grade']}/${sub['maxGrade'] ?? h['totalMarks'] ?? ''}',
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11),
                          if ((sub['feedback']?.toString() ?? '').isNotEmpty)
                            CustomText(
                                text: 'Feedback: ${sub['feedback']}',
                                color: AppColors.muted,
                                fontSize: 10.5,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                        ],
                        if (canSubmit && !isSubmitted) ...[
                          const CustomText(
                              text: 'Tap to submit your answer',
                              color: AppColors.blue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700),
                          const SizedBox(height: 8),
                        ],
                        AppProgressBar(
                            percent: isSubmitted ? 100 : (isOverdue ? 20 : 60),
                            color: isSubmitted
                                ? AppColors.secondryColor
                                : (isOverdue
                                    ? AppColors.red
                                    : AppColors.amber)),
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

extension on HomeworkScreen {
  void _openDetail(BuildContext context, Map<String, dynamic> h) {
    final sub = h['mySubmission'] is Map ? Map<String, dynamic>.from(h['mySubmission'] as Map) : null;
    final status = sub?['status']?.toString();
    final graded = status == 'graded';
    final id = h['_id']?.toString() ?? '';
    final existing = sub?['textResponse']?.toString() ?? '';
    final textCtrl = TextEditingController(text: existing);
    final details = [
      if ((h['description']?.toString() ?? '').isNotEmpty) h['description'].toString(),
      if ((h['instructions']?.toString() ?? '').isNotEmpty) h['instructions'].toString(),
    ].join('\n\n');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomBottomSheet(
        title: h['title']?.toString() ?? 'Homework',
        widget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.isNotEmpty) ...[
              CustomText(text: details, color: AppColors.muted, fontSize: 12),
              const SizedBox(height: 14),
            ],
            if (sub == null)
              const CustomText(
                  text: "This homework isn't on your child's class roster yet, so it can't be submitted from here.",
                  color: AppColors.muted,
                  fontSize: 12)
            else if (graded) ...[
              if (existing.isNotEmpty) CustomText(text: 'Your answer: $existing', color: AppColors.ink, fontSize: 12),
              const SizedBox(height: 8),
              const CustomText(
                  text: 'Graded - this can no longer be resubmitted.', color: AppColors.muted, fontSize: 11.5),
            ] else ...[
              CustomTextField(
                controller: textCtrl,
                maxLines: 5,
                label: 'Your answer',
                isborder: true,
                fillColor: AppColors.background,
              ),
              const SizedBox(height: 18),
              Obx(() => CustomButton(
                    label: controller.submittingId.value == id
                        ? ''
                        : (status == 'submitted' || status == 'late' ? 'Resubmit' : 'Submit'),
                    width: double.infinity,
                    height: 48,
                    color: AppColors.primaryColor,
                    enabled: controller.submittingId.value != id,
                    prefix: controller.submittingId.value == id
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : null,
                    onPressed: () async {
                      final text = textCtrl.text.trim();
                      if (text.isEmpty) {
                        CustomAppSnackbar.error('Please write your answer first.');
                        return;
                      }
                      final err = await controller.submit(id, text);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (err == null) {
                        CustomAppSnackbar.success('Homework submitted.');
                      } else {
                        CustomAppSnackbar.error(err);
                      }
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: CustomText(
              text: label,
              color: AppColors.muted,
              fontSize: 10,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        CustomText(
            text: value,
            color: AppColors.primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w800),
      ],
    );
  }
}
