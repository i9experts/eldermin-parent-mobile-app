import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_bottom_sheet.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text.dart';
import '../../../components/custom_text_field.dart';
import '../controllers/home_tasks_controller.dart';

/// Tarbiyah-at-home: tasks a teacher assigned for the parent to do with
/// their child outside school. Marking one complete is the parent's side
/// of the loop - a teacher may later add an optional rating/review, but
/// that never has to happen for this to count as done. Mirrors
/// LeavesScreen's structure for a consistent navigation/styling feel.
class HomeTasksScreen extends GetView<HomeTasksController> {
  const HomeTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Home tasks',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      body: Obx(() {
        if (controller.loading.value && controller.tasks.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 90),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerStatsRowSkeleton(count: 2),
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

        final tasks = controller.tasks;
        final completed =
            tasks.where((t) => t['status'] == 'completed').length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 90),
            children: [
              const ScreenHeader(
                title: 'Home tasks',
                caption: 'Small Tarbiyah tasks to practice at home',
                selectLabel: 'Academic year',
              ),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${tasks.length}', 'Assigned', null),
                ('$completed', 'Completed', null),
              ]),
              const SizedBox(height: AppSpacing.lg),
              const SectionRow(title: 'Tasks'),
              if (tasks.isEmpty)
                const AppEmptyView(
                    icon: Icons.favorite_outline,
                    title: 'No home tasks yet',
                    subtitle:
                        'Tasks your child\'s teacher assigns will appear here.')
              else
                ...tasks.map((raw) {
                  final t = Map<String, dynamic>.from(raw as Map);
                  final status = t['status']?.toString() ?? 'assigned';
                  final isCompleted = status == 'completed';
                  final due = DateTime.tryParse(t['dueDate']?.toString() ?? '');
                  final id = t['_id']?.toString() ?? '';

                  return Obx(() {
                    final isSubmitting = controller.completingId.value == id;
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                    text: t['title']?.toString() ??
                                        'Home task',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: AppColors.primaryColor,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              AppTag(isCompleted ? 'Completed' : 'To do',
                                  style: isCompleted
                                      ? TagStyle.green
                                      : TagStyle.amber),
                            ],
                          ),
                          if ((t['description']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            CustomText(
                                text: t['description'].toString(),
                                color: AppColors.muted,
                                fontSize: 11.5,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                          ],
                          if (due != null) ...[
                            const SizedBox(height: 4),
                            CustomText(
                                text:
                                    'Due ${due.day}/${due.month}/${due.year}',
                                color: AppColors.muted,
                                fontSize: 9.5),
                          ],
                          if (!isCompleted) ...[
                            const SizedBox(height: 10),
                            CustomButton(
                              label: isSubmitting ? '' : 'Mark complete',
                              width: double.infinity,
                              height: 40,
                              color: AppColors.primaryColor,
                              enabled: !isSubmitting,
                              prefix: isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : null,
                              onPressed: () => _openCompleteSheet(context, id),
                            ),
                          ] else if ((t['parentNotes']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            CustomText(
                                text: '"${t['parentNotes']}"',
                                color: AppColors.muted,
                                fontSize: 10.5),
                          ],
                        ],
                      ),
                    );
                  });
                }),
            ],
          ),
        );
      }),
    );
  }

  void _openCompleteSheet(BuildContext context, String taskId) {
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return CustomBottomSheet(
          title: 'Mark as complete',
          widget: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: notesCtrl,
                maxLines: 4,
                label: 'How did it go? (optional)',
                isborder: true,
                fillColor: AppColors.background,
              ),
              const SizedBox(height: 18),
              Obx(() => CustomButton(
                    label: controller.completingId.value == taskId
                        ? ''
                        : 'Done',
                    width: double.infinity,
                    height: 48,
                    color: AppColors.primaryColor,
                    enabled: controller.completingId.value != taskId,
                    prefix: controller.completingId.value == taskId
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : null,
                    onPressed: () async {
                      final ok = await controller.complete(taskId,
                          parentNotes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim());
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (ok) {
                        CustomAppSnackbar.success('Marked as complete.');
                      } else {
                        CustomAppSnackbar.error('Please try again.');
                      }
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}
