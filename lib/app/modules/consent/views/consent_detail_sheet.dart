import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/widgets/detail_bottom_sheet.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../students/controllers/student_controller.dart';
import '../controllers/consent_controller.dart';

const _categories = {
  'field_trip': 'Field trip',
  'medical': 'Medical',
  'photo_video': 'Photo / video',
  'data_sharing': 'Data sharing',
  'other': 'Other',
};

String _date(DateTime d) => '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';

String? _dateOf(Object? iso, {bool utcDay = false}) {
  final d = DateTime.tryParse(iso?.toString() ?? '');
  if (d == null) return null;
  return _date(utcDay ? d.toUtc() : d.toLocal());
}

String _fileName(String url, int i) {
  final seg = Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
  return seg == null || seg.isEmpty ? 'Attachment ${i + 1}' : Uri.decodeComponent(seg);
}

/// Opens the consent detail sheet for [id]. Only the selected student's own data is shown; `studentIds` (the whole cohort) never is.
Future<void> showConsentDetailSheet(BuildContext context, ConsentController c, String id) {
  c.respondError.value = null; // a failure from an earlier sheet is not this one's
  return DetailBottomSheet.show<void>(context, reactive: true, data: () => consentSheetData(c, id));
}

/// What the sheet shows for request [id], read from the controller's current copy.
DetailSheetData consentSheetData(ConsentController c, String id) {
  final r = c.byId(id);
  if (r == null) return const DetailSheetData(title: 'Consent request', notice: 'This request is no longer available.');
  final status = ConsentController.statusOf(r);
  final response = r['response'] is Map ? Map<String, dynamic>.from(r['response'] as Map) : null;
  final decision = response?['decision']?.toString();
  final student = Get.isRegistered<StudentController>() ? Get.find<StudentController>().selectedStudent : null;
  final due = ConsentController.dueEnd(r);
  final attachments = [for (final a in (r['attachments'] as List? ?? const [])) a.toString()].where((u) => u.trim().isNotEmpty).toList();

  final (label, tone) = switch (status) {
    ConsentStatus.pending => ('Pending', EmTone.warning),
    ConsentStatus.expired => ('Expired', EmTone.error),
    ConsentStatus.responded => (decision == 'granted' ? 'Granted' : 'Declined', decision == 'granted' ? EmTone.success : EmTone.error),
  };

  return DetailSheetData(
    title: r['title']?.toString() ?? 'Consent request',
    statusLabel: label,
    statusTone: tone,
    notice: status == ConsentStatus.expired ? 'The response date has passed. Please contact the school if you still need to respond.' : null,
    fields: [
      DetailField('Student', student == null ? null : '${student.fullName}${student.currentGrade.isEmpty ? '' : ' · Class ${student.gradeSection}'}'),
      DetailField('Category', _categories[r['category']?.toString()] ?? r['category']?.toString()),
      DetailField('Requested by', r['createdBy']?.toString()),
      DetailField('Sent on', _dateOf(r['createdAt'])),
      DetailField('Respond by', due == null ? null : _dateOf(r['dueDate'], utcDay: true)),
    ],
    longTextLabel: 'Details',
    longText: r['description']?.toString(),
    longTextIsRich: true,
    attachments: [for (var i = 0; i < attachments.length; i++) DetailAttachment(_fileName(attachments[i], i), attachments[i])],
    sections: [
      if (status == ConsentStatus.responded && response != null)
        DetailSection('Your response', [
          DetailField('Decision', decision == 'granted' ? 'Consent granted' : 'Consent declined'),
          DetailField('Responded by', response['respondedByName']?.toString()),
          // `updatedAt` here is the response document's own timestamp (consent_responses has timestamps), not the request's.
          DetailField('Responded on', _dateOf(response['updatedAt'] ?? response['createdAt'])),
          DetailField('Note', response['notes']?.toString()),
        ]),
    ],
    footer: status == ConsentStatus.pending ? ConsentActions(controller: c, request: r) : null,
  );
}

/// Grant / Decline with a confirmation each. Decline also asks for an optional reason (sent as `notes`).
class ConsentActions extends StatelessWidget {
  const ConsentActions({super.key, required this.controller, required this.request});
  final ConsentController controller;
  final Map<String, dynamic> request;

  String get _id => ConsentController.idOf(request);

  Future<void> _submit(BuildContext context, String decision) async {
    final title = request['title']?.toString() ?? 'this request';
    String? notes;
    if (decision == 'granted') {
      // Navigator.pop, not Get.back: Get.back closes an open snackbar (e.g. the previous failure) instead of the dialog.
      final ok = await Get.dialog<bool>(Builder(
        builder: (ctx) => EmDialog(
          title: 'Grant consent?',
          message: 'You are giving consent for "$title". This cannot be changed from the app afterwards.',
          actions: [
            EmDialogAction(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
            EmDialogAction(label: 'Grant consent', tone: EmDialogTone.primary, onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ));
      if (ok != true) return;
    } else {
      final reason = await Get.dialog<String>(_DeclineDialog(title: title));
      if (reason == null) return;
      notes = reason;
    }
    final saved = await controller.respond(_id, decision, notes: notes);
    if (saved) {
      if (context.mounted) Navigator.of(context).pop();
      CustomAppSnackbar.success(decision == 'granted' ? 'Response recorded — consent granted.' : 'Response recorded — consent declined.');
    } else {
      CustomAppSnackbar.error(controller.respondError.value ?? 'Could not submit your response. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.respondingId.value != null;
      final mine = controller.respondingId.value == _id;
      final err = controller.respondError.value;
      final decline = EmSecondaryButton(key: const Key('consent_decline'), label: 'Decline', expand: true, onPressed: busy ? null : () => _submit(context, 'declined'));
      final grant = EmPrimaryButton(key: const Key('consent_grant'), label: 'Grant consent', loading: mine, onPressed: busy ? null : () => _submit(context, 'granted'));
      final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.15;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (err != null) ...[
          Text(err, key: const Key('consent_error'), style: EmType.caption.copyWith(color: EmColors.error)),
          const SizedBox(height: EmSpacing.s8),
        ],
        if (stacked) ...[decline, const SizedBox(height: EmSpacing.s8), grant] else Row(children: [Expanded(child: decline), const SizedBox(width: EmSpacing.s8), Expanded(child: grant)]),
      ]);
    });
  }
}

/// Decline confirmation with an optional reason. Pops the reason ('' when left empty) or null when cancelled.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog({required this.title});
  final String title;

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EmDialog(
      title: 'Decline consent?',
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('You are declining "${widget.title}". This cannot be changed from the app afterwards.', style: EmType.bodyRegular.copyWith(color: EmColors.textSecondary, height: 1.5)),
        const SizedBox(height: EmSpacing.s12),
        EmTextField(key: const Key('consent_reason'), label: 'Reason (optional)', controller: _reason, maxLines: 3, textInputAction: TextInputAction.newline),
      ]),
      actions: [
        EmDialogAction(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        EmDialogAction(label: 'Decline', tone: EmDialogTone.destructive, onPressed: () => Navigator.of(context).pop(_reason.text.trim())),
      ],
    );
  }
}
