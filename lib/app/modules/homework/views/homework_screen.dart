import 'package:flutter/material.dart';
import '../../../../core/utils/greeting.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_bottom_sheet.dart';
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
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(),
                const SizedBox(height: EmSpacing.s16),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: EmSpacing.s12),
                const ShimmerChartSkeleton(),
                const SizedBox(height: EmSpacing.s12),
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
            padding: EmSpacing.listPadding,
            children: [
              ScreenIntro(
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
              StatsRow(items: [
                ('${items.length}', 'Assigned', null),
                ('$completedCount', 'Completed', null),
                ('$pendingCount', 'Pending', null),
              ]),
              if (items.isNotEmpty) ...[
                const SizedBox(height: EmSpacing.s12),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DonutRing(percent: completionPct, color: EmColors.primary),
                      const SizedBox(width: EmSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Weekly completion', style: EmType.label.copyWith(color: EmColors.ink)),
                            const SizedBox(height: EmSpacing.s8),
                            _LegendRow(
                                color: EmColors.success,
                                label: 'Submitted',
                                value: '$completedCount'),
                            const SizedBox(height: EmSpacing.s4),
                            _LegendRow(
                                color: EmColors.accent,
                                label: 'Pending',
                                value: '$pendingCount'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: EmSpacing.s12),
              SegmentedControl(
                  options: const ['All tasks', 'Pending', 'Submitted'],
                  selectedIndex: controller.filter.value,
                  onChanged: controller.changeFilter),
              const SizedBox(height: EmSpacing.s12),
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
                      due.isBefore(uiNow());
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
                          Expanded(child: Text('${h['subject'] ?? 'Subject'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.bodyLarge.copyWith(color: EmColors.ink))),
                          const SizedBox(width: EmSpacing.s8),
                          AppTag(
                            isSubmitted ? 'Submitted' : (isOverdue ? 'Overdue' : (due != null ? 'Due ${due.day}/${due.month}' : 'Pending')),
                            style: isSubmitted ? TagStyle.green : (isOverdue ? TagStyle.red : TagStyle.amber),
                          ),
                        ]),
                        const SizedBox(height: EmSpacing.s4),
                        Text('${h['title'] ?? h['description'] ?? ''}',
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.label.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
                        const SizedBox(height: EmSpacing.s12),
                        if (graded && sub?['grade'] != null) ...[
                          Text('Score: ${sub!['grade']}/${sub['maxGrade'] ?? h['totalMarks'] ?? ''}', style: EmType.label.copyWith(color: EmColors.ink)),
                          if ((sub['feedback']?.toString() ?? '').isNotEmpty)
                            Text('Feedback: ${sub['feedback']}',
                                maxLines: 3, overflow: TextOverflow.ellipsis, style: EmType.label.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
                          const SizedBox(height: EmSpacing.s8),
                        ],
                        if (canSubmit && !isSubmitted) ...[
                          Text('Tap to submit your answer', style: EmType.label.copyWith(color: EmColors.primary)),
                          const SizedBox(height: EmSpacing.s8),
                        ],
                        AppProgressBar(
                            percent: isSubmitted ? 100 : (isOverdue ? 20 : 60),
                            color: isSubmitted ? EmColors.success : (isOverdue ? EmColors.error : EmColors.accent)),
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
              Text(details, style: EmType.body.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
              const SizedBox(height: EmSpacing.s16),
            ],
            if (sub == null)
              Text("This homework isn't on your child's class roster yet, so it can't be submitted from here.",
                  style: EmType.body.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400))
            else if (graded) ...[
              if (existing.isNotEmpty) Text('Your answer: $existing', style: EmType.body.copyWith(color: EmColors.ink)),
              const SizedBox(height: EmSpacing.s8),
              Text('Graded - this can no longer be resubmitted.', style: EmType.label.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
            ] else ...[
              EmTextField(
                controller: textCtrl,
                maxLines: 5,
                label: 'Your answer',
                fillColor: EmColors.background,
              ),
              const SizedBox(height: EmSpacing.s20),
              Obx(() => EmPrimaryButton(
                    label: status == 'submitted' || status == 'late' ? 'Resubmit' : 'Submit',
                    loading: controller.submittingId.value == id,
                    onPressed: controller.submittingId.value == id
                        ? null
                        : () async {
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: EmSpacing.s8),
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.caption.copyWith(color: EmColors.textSecondary))),
        Text(value, style: EmType.valueSmall.copyWith(color: EmColors.ink)),
      ],
    );
  }
}
