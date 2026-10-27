import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart' show TagStyle;
import '../../../../core/utils/greeting.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_bottom_sheet.dart';
import '../../../components/custom_text_field.dart';
import '../controllers/ptm_controller.dart';

/// Parent-teacher meetings. Teacher pattern: `design-kit-v1` `ptm_screen.dart:21-76` (scaffold, extended floating action button,
/// padded list with room for it), the meeting card `ptm_widgets.dart:31-71` (name + status tag, date row, quiet detail lines),
/// and the request form `ptm_new_screen.dart:49-117` (a pick field per date / time, inline errors `:129-133`, an
/// [EmPrimaryButton] with a loading state `:135-147`), shown in a sheet.
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
    return EmScaffold(
      appBar: EmAppBar(title: 'Parent-teacher meetings'),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('ptm_open_form'),
        onPressed: () => _openRequestSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request meeting'),
      ),
      body: Obx(() {
        if (controller.loading.value && controller.meetings.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPaddingFab,
              children: [
                const ShimmerScreenIntroSkeleton(withChip: false),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: EmSpacing.s16),
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
        final upcoming = meetings.where((m) => ['requested', 'confirmed'].contains(Map<String, dynamic>.from(m as Map)['status'])).length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPaddingFab,
            children: [
              const ScreenIntro(caption: 'Requests and meeting history'),
              StatsRow(items: [
                ('${meetings.length}', 'Total', null),
                ('$upcoming', 'Upcoming', null),
                ('$completed', 'Completed', null),
              ]),
              const SizedBox(height: EmSpacing.s16),
              if (meetings.isEmpty)
                const AppEmptyView(icon: Icons.groups_outlined, title: 'No meetings yet', subtitle: 'Parent-teacher meeting requests will appear here.')
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
                  final when = [
                    if (date != null) '${date.day}/${date.month}/${date.year}',
                    if (startTime != null) '$startTime${endTime != null ? '–$endTime' : ''}',
                  ].join(' · ');
                  final quiet = EmType.label.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400);

                  return AppCard(
                    key: ValueKey('ptm_${m['_id']}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(teacherName, maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.bodyLarge.copyWith(color: EmColors.ink))),
                            const SizedBox(width: EmSpacing.s8),
                            AppTag(status.replaceAll('_', ' '), style: _statusStyle(status)),
                          ],
                        ),
                        if (when.isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: EmSpacing.s4),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Padding(padding: EdgeInsetsDirectional.only(top: EmSpacing.s2), child: ExcludeSemantics(child: Icon(Icons.event_rounded, size: 16, color: EmColors.textSecondary))),
                              const SizedBox(width: EmSpacing.s8),
                              Expanded(child: Text(when, style: EmType.label.copyWith(color: EmColors.ink))),
                            ]),
                          ),
                        if (status == 'requested' || status == 'confirmed')
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: EmTextAction(
                              key: Key('ptm_cancel_${m['_id']}'),
                              label: 'Cancel request',
                              destructive: true,
                              onPressed: () async {
                                final err = await controller.cancel(m['_id'].toString());
                                if (err == null) {
                                  CustomAppSnackbar.success('Meeting request cancelled.');
                                } else {
                                  CustomAppSnackbar.error(err);
                                }
                              },
                            ),
                          ),
                        if (discussionPoints.isNotEmpty) ...[
                          const SizedBox(height: EmSpacing.s8),
                          Text('Discussion points', style: EmType.label.copyWith(color: EmColors.ink)),
                          const SizedBox(height: EmSpacing.s4),
                          ...discussionPoints.map((p) => Padding(
                                padding: const EdgeInsetsDirectional.only(top: EmSpacing.s2),
                                child: Text('• ${p.toString()}', style: EmType.body.copyWith(color: EmColors.ink, fontWeight: FontWeight.w400)),
                              )),
                        ],
                        if (meetingNotes != null && meetingNotes.isNotEmpty) ...[
                          const SizedBox(height: EmSpacing.s8),
                          Text('Notes', style: EmType.label.copyWith(color: EmColors.ink)),
                          const SizedBox(height: EmSpacing.s4),
                          Text(meetingNotes, style: quiet.copyWith(color: EmColors.ink)),
                        ],
                        if (actionItems.isNotEmpty) ...[
                          const SizedBox(height: EmSpacing.s8),
                          Text('Action items', style: EmType.label.copyWith(color: EmColors.ink)),
                          const SizedBox(height: EmSpacing.s8),
                          ...actionItems.map((raw2) {
                            final item = Map<String, dynamic>.from(raw2 as Map);
                            final done = item['status']?.toString() == 'done';
                            return Padding(
                              padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(item['description']?.toString() ?? '', style: EmType.body.copyWith(color: EmColors.ink, fontWeight: FontWeight.w400))),
                                  const SizedBox(width: EmSpacing.s8),
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
    var sending = false; // submit-once guard for the same frame (the button also shows its loading state)
    String? serverError;
    final errors = <String, String>{};
    controller.loadTeachers();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          Future<void> submit() async {
            if (sending) return;
            if (teacherId == null || date == null) {
              setState(() {
                errors
                  ..clear()
                  ..addAll({
                    if (teacherId == null) 'teacher': 'Choose a teacher.',
                    if (date == null) 'date': 'Choose a preferred date.',
                  });
              });
              CustomAppSnackbar.warning('Please choose a teacher and a preferred date.');
              return;
            }
            sending = true;
            setState(() {
              serverError = null;
              errors.clear();
            });
            try {
              final hh = time?.hour.toString().padLeft(2, '0');
              final mm = time?.minute.toString().padLeft(2, '0');
              final err = await controller.request(
                teacherId: teacherId!,
                date: date!,
                time: time == null ? null : '$hh:$mm',
                reason: reasonCtrl.text.trim(),
              );
              if (err == null) {
                if (ctx.mounted) Navigator.of(ctx).pop();
                CustomAppSnackbar.success('Meeting request sent to the school.');
              } else {
                // the form is kept (nothing the parent typed is lost) and the reason is shown in it
                if (ctx.mounted) setState(() => serverError = err);
                CustomAppSnackbar.error(err);
              }
            } finally {
              sending = false;
            }
          }

          return CustomBottomSheet(
            title: 'Request a meeting',
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (serverError != null) ...[
                  EmInfoBanner(key: const Key('ptm_form_error'), text: serverError!, tone: EmTone.error, icon: Icons.error_outline_rounded),
                  const SizedBox(height: EmSpacing.s12),
                ],
                Obx(() {
                  final list = controller.teachers;
                  if (list.isEmpty) {
                    return Text('No teachers found for this class yet.', style: EmType.body.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400));
                  }
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    DropdownButtonFormField<String>(
                      key: const Key('ptm_teacher'),
                      initialValue: teacherId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Teacher'),
                      items: list.map((raw) {
                        final t = Map<String, dynamic>.from(raw as Map);
                        final subjects = (t['subjects'] as List?)?.join(', ') ?? '';
                        return DropdownMenuItem<String>(
                          value: t['teacherId'].toString(),
                          child: Text(subjects.isEmpty ? '${t['teacherName']}' : '${t['teacherName']} · $subjects', maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() {
                        teacherId = v;
                        errors.remove('teacher');
                      }),
                    ),
                    if (errors['teacher'] != null) AppFieldError(errors['teacher']!),
                  ]);
                }),
                const SizedBox(height: EmSpacing.s12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const AppFormLabel('Date'),
                      AppPickField(
                        key: const Key('ptm_date'),
                        icon: Icons.event_rounded,
                        text: date == null ? 'Preferred date' : '${date!.day}/${date!.month}/${date!.year}',
                        filled: date != null,
                        error: errors['date'],
                        onTap: () async {
                          final now = uiNow();
                          final picked = await showAppDatePicker(ctx,
                              initialDate: now.add(const Duration(days: 1)), firstDate: now, lastDate: now.add(const Duration(days: 180)));
                          if (picked != null) {
                            setState(() {
                              date = picked;
                              errors.remove('date');
                            });
                          }
                        },
                      ),
                      if (errors['date'] != null) AppFieldError(errors['date']!),
                    ]),
                  ),
                  const SizedBox(width: EmSpacing.s12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const AppFormLabel('Time'),
                      AppPickField(
                        key: const Key('ptm_time'),
                        icon: Icons.schedule_rounded,
                        text: time == null ? 'Preferred time' : time!.format(ctx),
                        filled: time != null,
                        onTap: () async {
                          final picked = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 10, minute: 0));
                          if (picked != null) setState(() => time = picked);
                        },
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: EmSpacing.s12),
                CustomTextField(
                  key: const Key('ptm_reason'),
                  controller: reasonCtrl,
                  maxLines: 3,
                  label: 'What would you like to discuss?',
                  fillColor: EmColors.background,
                ),
                const SizedBox(height: EmSpacing.s20),
                Obx(() => EmPrimaryButton(
                      key: const Key('ptm_submit'),
                      label: controller.submitting.value ? 'Sending' : 'Send request',
                      loading: controller.submitting.value,
                      onPressed: controller.submitting.value ? null : submit,
                    )),
              ],
            ),
          );
        });
      },
    );
  }
}
