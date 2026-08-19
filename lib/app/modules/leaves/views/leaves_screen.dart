import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_bottom_sheet.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text.dart';
import '../../../components/custom_text_field.dart';
import '../controllers/leaves_controller.dart';

class LeavesScreen extends GetView<LeavesController> {
  const LeavesScreen({super.key});

  TagStyle _styleFor(String status) {
    switch (status) {
      case 'approved':
        return TagStyle.green;
      case 'rejected':
        return TagStyle.red;
      default:
        return TagStyle.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Leave requests',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRequestSheet(context),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const CustomText(
            text: 'Request leave',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700),
      ),
      body: Obx(() {
        if (controller.loading.value && controller.leaves.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 90),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerDateStripSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerChartSkeleton(),
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

        final leaves = controller.leaves;
        final pending = leaves.where((l) => l['status'] == 'pending').length;
        final approved = leaves.where((l) => l['status'] == 'approved').length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 90),
            children: [
              const ScreenHeader(
                title: 'Leave requests',
                caption: 'Plan, submit and track absences',
                selectLabel: 'Academic year',
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${leaves.length}', 'Requests', null),
                ('$pending', 'Pending', pending == 0 ? 'None' : null),
                ('$approved', 'Approved', null),
              ]),
              const SizedBox(height: AppSpacing.lg),
              if (leaves.isNotEmpty) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                              text: 'Requests approved',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.primaryColor),
                          AppTag('$approved of ${leaves.length}', style: TagStyle.green),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppProgressBar(
                        percent: ((approved / leaves.length) * 100).round(),
                        color: AppColors.secondryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SectionRow(title: 'History'),
              if (leaves.isEmpty)
                const AppEmptyView(
                    icon: Icons.event_available_outlined,
                    title: 'No leave requests yet',
                    subtitle: 'Requests you submit will appear here.')
              else
                ...leaves.map((raw) {
                  final l = Map<String, dynamic>.from(raw as Map);
                  final status = l['status']?.toString() ?? 'pending';
                  final from =
                      DateTime.tryParse(l['fromDate']?.toString() ?? '');
                  final to = DateTime.tryParse(l['toDate']?.toString() ?? '');
                  final range = from != null && to != null
                      ? (from.day == to.day && from.month == to.month
                          ? '${from.day}/${from.month}/${from.year}'
                          : '${from.day}/${from.month} – ${to.day}/${to.month}/${to.year}')
                      : '';
                  return AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                  text: l['reason']?.toString() ??
                                      'Leave request',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AppColors.primaryColor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              CustomText(
                                  text: range,
                                  color: AppColors.muted,
                                  fontSize: 9.5,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        AppTag(status[0].toUpperCase() + status.substring(1),
                            style: _styleFor(status)),
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

  void _openRequestSheet(BuildContext context) {
    DateTime? from;
    DateTime? to;
    String leaveType = 'other';
    final reasonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> pickDate(bool isFrom) async {
              final picked = await showAppDatePicker(
                ctx,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null)
                setState(() => isFrom ? from = picked : to = picked);
            }

            return CustomBottomSheet(
              title: 'New leave request',
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickDate(true),
                          child: CustomText(
                              text: from == null
                                  ? 'From date'
                                  : '${from!.day}/${from!.month}/${from!.year}',
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickDate(false),
                          child: CustomText(
                              text: to == null
                                  ? 'To date'
                                  : '${to!.day}/${to!.month}/${to!.year}',
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: leaveType,
                    decoration: const InputDecoration(labelText: 'Leave type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'sick',
                          child: CustomText(text: 'Sick', fontSize: 14)),
                      DropdownMenuItem(
                          value: 'family',
                          child: CustomText(text: 'Family', fontSize: 14)),
                      DropdownMenuItem(
                          value: 'travel',
                          child: CustomText(text: 'Travel', fontSize: 14)),
                      DropdownMenuItem(
                          value: 'other',
                          child: CustomText(text: 'Other', fontSize: 14)),
                    ],
                    onChanged: (v) => setState(() => leaveType = v ?? 'other'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: reasonCtrl,
                    maxLines: 4,
                    label: 'Reason',
                    isborder: true,
                    fillColor: AppColors.background,
                  ),
                  const SizedBox(height: 18),
                  Obx(() => CustomButton(
                        label: controller.submitting.value
                            ? ''
                            : 'Submit request',
                        width: double.infinity,
                        height: 48,
                        color: AppColors.primaryColor,
                        enabled: !controller.submitting.value,
                        prefix: controller.submitting.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : null,
                        onPressed: () async {
                          if (from == null ||
                              to == null ||
                              reasonCtrl.text.trim().isEmpty) {
                            CustomAppSnackbar.warning(
                                'Please pick both dates and add a reason.');
                            return;
                          }
                          final ok = await controller.submit(
                              from: from!,
                              to: to!,
                              reason: reasonCtrl.text.trim(),
                              leaveType: leaveType);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (ok) {
                            CustomAppSnackbar.success(
                                'Your leave request has been submitted.');
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
      },
    );
  }
}
