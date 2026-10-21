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
import '../controllers/ptm_controller.dart';

class PtmScreen extends GetView<PtmController> {
  const PtmScreen({super.key});

  TagStyle _statusStyle(String status) {
    switch (status) {
      case 'confirmed':
        return TagStyle.info;
      case 'completed':
        return TagStyle.green;
      case 'cancelled':
      case 'no_show':
        return TagStyle.red;
      default:
        return TagStyle.amber; // requested
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Parent-teacher meetings',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRequestSheet(context),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const CustomText(
            text: 'Request meeting', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
      ),
      body: Obx(() {
        if (controller.loading.value && controller.meetings.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(withChip: false),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(5),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }

        final meetings = controller.meetings;
        final completed = meetings.where((m) => Map<String, dynamic>.from(m as Map)['status'] == 'completed').length;
        final upcoming = meetings
            .where((m) => ['requested', 'confirmed'].contains(Map<String, dynamic>.from(m as Map)['status']))
            .length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(title: 'Parent-teacher meetings', caption: 'Requests and meeting history'),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${meetings.length}', 'Total', null),
                ('$upcoming', 'Upcoming', null),
                ('$completed', 'Completed', null),
              ]),
              const SizedBox(height: AppSpacing.lg),
              if (meetings.isEmpty)
                const AppEmptyView(
                  icon: Icons.groups_outlined,
                  title: 'No meetings yet',
                  subtitle: 'Parent-teacher meeting requests will appear here.',
                )
              else
                ...meetings.map((raw) {
                  final m = Map<String, dynamic>.from(raw as Map);
                  final teacherName = m['teacherName']?.toString() ?? 'Teacher';
                  final status = m['status']?.toString() ?? 'requested';
                  final date = DateTime.tryParse(m['scheduledDate']?.toString() ?? '');
                  final startTime = m['startTime']?.toString();
                  final endTime = m['endTime']?.toString();
                  final discussionPoints = (m['discussionPoints'] as List<dynamic>?) ?? [];
                  final meetingNotes = m['meetingNotes']?.toString();
                  final actionItems = (m['actionItems'] as List<dynamic>?) ?? [];

                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                      text: teacherName,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.primaryColor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  CustomText(
                                    text: [
                                      if (date != null) '${date.day}/${date.month}/${date.year}',
                                      if (startTime != null) '$startTime${endTime != null ? '–$endTime' : ''}',
                                    ].join(' · '),
                                    color: AppColors.muted,
                                    fontSize: 9.5,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            AppTag(
                              status.replaceAll('_', ' '),
                              style: _statusStyle(status),
                            ),
                          ],
                        ),
                        if (status == 'requested' || status == 'confirmed') ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                final err = await controller.cancel(m['_id'].toString());
                                if (err == null) {
                                  CustomAppSnackbar.success('Meeting request cancelled.');
                                } else {
                                  CustomAppSnackbar.error(err);
                                }
                              },
                              child: const CustomText(
                                  text: 'Cancel request', color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        if (discussionPoints.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const CustomText(
                              text: 'Discussion points',
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              color: AppColors.primaryColor),
                          const SizedBox(height: 4),
                          ...discussionPoints.map((p) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: CustomText(
                                    text: '• ${p.toString()}',
                                    color: AppColors.ink,
                                    fontSize: 11),
                              )),
                        ],
                        if (meetingNotes != null && meetingNotes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const CustomText(
                              text: 'Notes',
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              color: AppColors.primaryColor),
                          const SizedBox(height: 4),
                          CustomText(
                              text: meetingNotes,
                              color: AppColors.ink,
                              fontSize: 11),
                        ],
                        if (actionItems.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const CustomText(
                              text: 'Action items',
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              color: AppColors.primaryColor),
                          const SizedBox(height: 6),
                          ...actionItems.map((raw2) {
                            final item = Map<String, dynamic>.from(raw2 as Map);
                            final done = item['status']?.toString() == 'done';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomText(
                                        text: item['description']?.toString() ?? '',
                                        color: AppColors.ink,
                                        fontSize: 11,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  AppTag(done ? 'Done' : 'Pending', style: done ? TagStyle.green : TagStyle.neutral),
                                ],
                              ),
                            );
                          }),
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

  void _openRequestSheet(BuildContext context) {
    String? teacherId;
    DateTime? date;
    TimeOfDay? time;
    final reasonCtrl = TextEditingController();
    controller.loadTeachers();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return CustomBottomSheet(
            title: 'Request a meeting',
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final list = controller.teachers;
                  if (list.isEmpty) {
                    return const CustomText(
                        text: 'No teachers found for this class yet.', color: AppColors.muted, fontSize: 12);
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: teacherId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Teacher'),
                    items: list.map((raw) {
                      final t = Map<String, dynamic>.from(raw as Map);
                      final subjects = (t['subjects'] as List?)?.join(', ') ?? '';
                      return DropdownMenuItem<String>(
                        value: t['teacherId'].toString(),
                        child: CustomText(
                            text: subjects.isEmpty ? '${t['teacherName']}' : '${t['teacherName']} · $subjects',
                            fontSize: 14,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => teacherId = v),
                  );
                }),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showAppDatePicker(ctx,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 180)));
                        if (picked != null) setState(() => date = picked);
                      },
                      child: CustomText(
                          text: date == null ? 'Preferred date' : '${date!.day}/${date!.month}/${date!.year}',
                          color: AppColors.primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                            context: ctx, initialTime: const TimeOfDay(hour: 10, minute: 0));
                        if (picked != null) setState(() => time = picked);
                      },
                      child: CustomText(
                          text: time == null ? 'Preferred time' : time!.format(ctx),
                          color: AppColors.primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  label: 'What would you like to discuss?',
                  isborder: true,
                  fillColor: AppColors.background,
                ),
                const SizedBox(height: 18),
                Obx(() => CustomButton(
                      label: controller.submitting.value ? '' : 'Send request',
                      width: double.infinity,
                      height: 48,
                      color: AppColors.primaryColor,
                      enabled: !controller.submitting.value,
                      prefix: controller.submitting.value
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : null,
                      onPressed: () async {
                        if (teacherId == null || date == null) {
                          CustomAppSnackbar.warning('Please choose a teacher and a preferred date.');
                          return;
                        }
                        final hh = time?.hour.toString().padLeft(2, '0');
                        final mm = time?.minute.toString().padLeft(2, '0');
                        final err = await controller.request(
                          teacherId: teacherId!,
                          date: date!,
                          time: time == null ? null : '$hh:$mm',
                          reason: reasonCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (err == null) {
                          CustomAppSnackbar.success('Meeting request sent to the school.');
                        } else {
                          CustomAppSnackbar.error(err);
                        }
                      },
                    )),
              ],
            ),
          );
        });
      },
    );
  }
}
