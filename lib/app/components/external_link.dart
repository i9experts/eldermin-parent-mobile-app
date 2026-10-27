// Mirrored from eldermin-teacher-app lib/app/components/external_link.dart (design-kit-v1, 2f2f5a6) — keep in sync.
// Parent copy: the confirmation uses EmDialog (the parent app has no ConfirmDialog), mailto:/tel: are allowed, and attachments can skip the prompt.
import 'package:flutter/widgets.dart' show Builder, Navigator;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/design/design.dart';
import '../../core/utils/safe_text.dart';
import 'custom_app_snack_bar.dart';

/// Opens a server-supplied link outside the app, only for http, https, mailto and tel URLs. Links inside rich text ask first
/// ([openWithConfirm]); a school-uploaded attachment the parent explicitly tapped opens directly ([open]).
class ExternalLinks {
  ExternalLinks._();

  /// Test seam: replace to capture launches without a platform channel.
  static Future<bool> Function(Uri uri) launcher = (u) => launchUrl(u, mode: LaunchMode.externalApplication);

  /// Test seam for the confirmation dialog.
  static Future<bool> Function(Uri uri) confirm = _confirm;

  static Future<bool> _confirm(Uri u) async {
    // Navigator.pop, not Get.back: Get.back closes an open snackbar instead of the dialog.
    final ok = await Get.dialog<bool>(Builder(
      builder: (ctx) => EmDialog(
        title: 'Open this link?',
        message: u.scheme == 'http' || u.scheme == 'https'
            ? 'It opens outside Eldermin Parent:\n${u.host}${u.path.length > 1 ? u.path : ''}'
            : 'It opens outside Eldermin Parent:\n${u.toString()}',
        actions: [
          EmDialogAction(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
          EmDialogAction(label: 'Open', tone: EmDialogTone.primary, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    ));
    return ok ?? false;
  }

  static Future<void> openWithConfirm(String? url) async {
    final u = safeExternalUri(url);
    if (u == null) return;
    if (!await confirm(u)) return;
    await _launch(u);
  }

  /// Opens without a prompt (an attachment the user tapped). Same scheme whitelist.
  static Future<bool> open(String? url) async {
    final u = safeExternalUri(url);
    if (u == null) {
      CustomAppSnackbar.error("Couldn't open this link.");
      return false;
    }
    return _launch(u);
  }

  static Future<bool> _launch(Uri u) async {
    try {
      if (await launcher(u)) return true;
    } catch (_) {}
    CustomAppSnackbar.error("Couldn't open the link.");
    return false;
  }
}
