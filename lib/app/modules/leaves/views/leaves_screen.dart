import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart' show TagStyle;
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/utils/greeting.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_bottom_sheet.dart';
import '../../../components/custom_text_field.dart';
import '../controllers/leaves_controller.dart';

/// Leave requests. Teacher pattern: `design-kit-v1` `leave_screen.dart:43-76` (an [EmPrimaryButton] in a bottom bar instead of a
/// floating button, then a padded list), history cards `:106-120`; the application form follows `leave_apply_screen.dart:62-72`
/// (a pick field per date), `:98` (the reason field) and `:113` (an [EmPrimaryButton] with a loading state), shown in a sheet.
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
    return EmScaffold(
      extendBody: false,
      appBar: EmAppBar(title: 'Leave requests'),
      // a bottom bar, not a floating button: a floating button covered the status tag of the last card
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.screenH, EmSpacing.s12, EmSpacing.screenH, EmSpacing.s12),
          decoration: const BoxDecoration(color: EmColors.surface, border: Border(top: BorderSide(color: EmColors.border))),
          child: EmPrimaryButton(key: const Key('leave_open_form'), label: 'Request leave', icon: Icons.add_rounded, onPressed: () => _openRequestSheet(context)),
        ),
      ),
      body: Obx(() {
        if (controller.loading.value && controller.leaves.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: EmSpacing.s12),
                const ShimmerProgressCardSkeleton(),
                const SizedBox(height: EmSpacing.s16),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }

        final leaves = controller.leaves;
        final pending = leaves.where((l) => l['status'] == 'pending').length;
        final approved = leaves.where((l) => l['status'] == 'approved').length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              const ScreenIntro(caption: 'Plan, submit and track absences', selectLabel: 'Academic year'),
              StatsRow(items: [
                ('${leaves.length}', 'Requests', null),
                ('$pending', 'Pending', pending == 0 ? 'None' : null),
                ('$approved', 'Approved', null),
              ]),
              const SizedBox(height: EmSpacing.s12),
              if (leaves.isNotEmpty)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Requests approved', style: EmType.label.copyWith(color: EmColors.ink))),
                          AppTag('$approved of ${leaves.length}', style: TagStyle.green),
                        ],
                      ),
                      const SizedBox(height: EmSpacing.s12),
                      AppProgressBar(percent: ((approved / leaves.length) * 100).round(), color: EmColors.success),
                    ],
                  ),
                ),
              const SectionRow(title: 'History'),
              if (leaves.isEmpty)
                const AppEmptyView(icon: Icons.event_available_outlined, title: 'No leave requests yet', subtitle: 'Requests you submit will appear here.')
              else
                ...leaves.map((raw) {
                  final l = Map<String, dynamic>.from(raw as Map);
                  final status = l['status']?.toString() ?? 'pending';
                  final from = DateTime.tryParse(l['fromDate']?.toString() ?? '');
                  final to = DateTime.tryParse(l['toDate']?.toString() ?? '');
                  final range = from != null && to != null
                      ? (from.year == to.year && from.month == to.month && from.day == to.day
                          ? '${from.day}/${from.month}/${from.year}'
                          : '${from.day}/${from.month} – ${to.day}/${to.month}/${to.year}')
                      : '';
                  return AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l['reason']?.toString() ?? 'Leave request', style: EmType.bodyLarge.copyWith(color: EmColors.ink)),
                              if (range.isNotEmpty) Text(range, style: EmType.body.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
                              if (status != 'pending' && (l['approverNote']?.toString().isNotEmpty ?? false))
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(top: EmSpacing.s4),
                                  child: Text('${l['approverName'] ?? 'School'}: ${l['approverNote']}', style: EmType.label.copyWith(color: EmColors.ink, fontWeight: FontWeight.w400)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: EmSpacing.s8),
                        AppTag(status[0].toUpperCase() + status.substring(1), style: _styleFor(status)),
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
    var sending = false; // submit-once guard for the same frame (the button also shows its loading state)
    String? serverError;
    final errors = <String, String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> pickDate(bool isFrom) async {
              final now = uiNow();
              final picked = await showAppDatePicker(
                ctx,
                initialDate: now,
                firstDate: now.subtract(const Duration(days: 1)),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  if (isFrom) {
                    from = picked;
                    errors.remove('from');
                  } else {
                    to = picked;
                    errors.remove('to');
                  }
                });
              }
            }

            String label(DateTime? d, String empty) => d == null ? empty : '${d.day}/${d.month}/${d.year}';

            Future<void> submit() async {
              if (sending) return;
              if (from == null || to == null || reasonCtrl.text.trim().isEmpty) {
                setState(() {
                  errors
                    ..clear()
                    ..addAll({
                      if (from == null) 'from': 'Choose the first day.',
                      if (to == null) 'to': 'Choose the last day.',
                      if (reasonCtrl.text.trim().isEmpty) 'reason': 'Add a reason.',
                    });
                });
                CustomAppSnackbar.warning('Please pick both dates and add a reason.');
                return;
              }
              sending = true;
              setState(() {
                serverError = null;
                errors.clear();
              });
              try {
                final ok = await controller.submit(from: from!, to: to!, reason: reasonCtrl.text.trim(), leaveType: leaveType);
                if (ok) {
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  CustomAppSnackbar.success('Your leave request has been submitted.');
                } else {
                  // the form is kept (nothing the parent typed is lost) and the reason is shown in it
                  final message = controller.error.value ?? 'Please try again.';
                  if (ctx.mounted) setState(() => serverError = message);
                  CustomAppSnackbar.error(message);
                }
              } finally {
                sending = false;
              }
            }

            return CustomBottomSheet(
              title: 'New leave request',
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (serverError != null) ...[
                    EmInfoBanner(key: const Key('leave_form_error'), text: serverError!, tone: EmTone.error, icon: Icons.error_outline_rounded),
                    const SizedBox(height: EmSpacing.s12),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const AppFormLabel('From'),
                          AppPickField(key: const Key('leave_from'), icon: Icons.event_rounded, text: label(from, 'From date'), filled: from != null, error: errors['from'], onTap: () => pickDate(true)),
                          if (errors['from'] != null) AppFieldError(errors['from']!),
                        ]),
                      ),
                      const SizedBox(width: EmSpacing.s12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const AppFormLabel('To'),
                          AppPickField(key: const Key('leave_to'), icon: Icons.event_rounded, text: label(to, 'To date'), filled: to != null, error: errors['to'], onTap: () => pickDate(false)),
                          if (errors['to'] != null) AppFieldError(errors['to']!),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: EmSpacing.s12),
                  DropdownButtonFormField<String>(
                    key: const Key('leave_type'),
                    initialValue: leaveType,
                    decoration: const InputDecoration(labelText: 'Leave type'),
                    items: const [
                      DropdownMenuItem(value: 'sick', child: Text('Sick')),
                      DropdownMenuItem(value: 'family', child: Text('Family')),
                      DropdownMenuItem(value: 'travel', child: Text('Travel')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => leaveType = v ?? 'other'),
                  ),
                  const SizedBox(height: EmSpacing.s12),
                  CustomTextField(
                    key: const Key('leave_reason'),
                    controller: reasonCtrl,
                    maxLines: 4,
                    label: 'Reason',
                    fillColor: EmColors.background,
                    errorText: errors['reason'],
                    onChanged: (_) {
                      if (errors.containsKey('reason')) setState(() => errors.remove('reason'));
                    },
                  ),
                  const SizedBox(height: EmSpacing.s20),
                  Obx(() => EmPrimaryButton(
                        key: const Key('leave_submit'),
                        label: controller.submitting.value ? 'Submitting' : 'Submit request',
                        loading: controller.submitting.value,
                        onPressed: controller.submitting.value ? null : submit,
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
