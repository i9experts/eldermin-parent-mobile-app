import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/utils/detail_format.dart';
import '../../../../core/widgets/detail_bottom_sheet.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../controllers/circulars_controller.dart';

String _capitalise(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _fileName(String url, int i) {
  final seg = Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
  return seg == null || seg.isEmpty ? 'Attachment ${i + 1}' : Uri.decodeComponent(seg);
}

/// Opens the circular detail sheet. [snapshot] is the row that was tapped; the sheet follows the controller's current copy (so it reflects an
/// acknowledgement) when the circular has an id, and falls back to the snapshot otherwise (legacy document-based circulars have none).
Future<void> showCircularDetailSheet(BuildContext context, CircularsController c, Map<String, dynamic> snapshot) {
  final id = snapshot['_id']?.toString();
  c.acknowledgeError.value = null; // a failure from an earlier sheet is not this one's
  return DetailBottomSheet.show<void>(context, reactive: id != null, data: () => circularSheetData(c, (id == null ? null : c.byId(id)) ?? snapshot));
}

DetailSheetData circularSheetData(CircularsController c, Map<String, dynamic> item) {
  final id = item['_id']?.toString();
  final requires = item['requiresAcknowledgment'] == true;
  final acknowledged = item['acknowledged'] == true;
  final needsAck = requires && !acknowledged && id != null;
  final priority = item['priority']?.toString() ?? 'normal';
  final body = item['body']?.toString().trim() ?? '';
  final category = item['category']?.toString();
  final attachments = [for (final a in (item['attachmentUrls'] as List? ?? const [])) a.toString()].where((u) => u.trim().isNotEmpty).toList();

  final (label, tone) = requires
      ? (acknowledged ? ('Acknowledged', EmTone.success) : ('Acknowledgement needed', EmTone.warning))
      : (_capitalise(category ?? 'Notice'), EmTone.info);

  return DetailSheetData(
    title: item['title']?.toString() ?? 'Notice',
    statusLabel: label,
    statusTone: tone,
    fields: [
      DetailField('Category', category == null ? null : _capitalise(category)),
      DetailField('Priority', priority == 'normal' ? null : _capitalise(priority)),
      DetailField('Published', formatDayOf(item['effectiveDate'] ?? item['createdAt'])),
    ],
    longTextLabel: 'Details',
    longText: body,
    notice: body.isEmpty ? 'No further details.' : null,
    attachments: [for (var i = 0; i < attachments.length; i++) DetailAttachment(_fileName(attachments[i], i), attachments[i])],
    footer: needsAck ? CircularAcknowledge(controller: c, id: id) : null,
  );
}

class CircularAcknowledge extends StatelessWidget {
  const CircularAcknowledge({super.key, required this.controller, required this.id});
  final CircularsController controller;
  final String id;

  Future<void> _ack(BuildContext context) async {
    final ok = await controller.acknowledge(id);
    if (ok) {
      if (context.mounted) Navigator.of(context).pop();
      CustomAppSnackbar.success('Thank you — acknowledged.');
    } else {
      CustomAppSnackbar.error(controller.acknowledgeError.value ?? 'Could not acknowledge. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.acknowledgingId.value != null;
      final err = controller.acknowledgeError.value;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (err != null) ...[
          Text(err, key: const Key('circular_error'), style: EmType.caption.copyWith(color: EmColors.error)),
          const SizedBox(height: EmSpacing.s8),
        ],
        EmPrimaryButton(key: const Key('circular_acknowledge'), label: 'Acknowledge', loading: busy, onPressed: busy ? null : () => _ack(context)),
      ]);
    });
  }
}
