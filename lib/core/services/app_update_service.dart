import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/api_constants.dart';
import '../design/design.dart';
import '../network/base_client.dart';
import '../utils/app_log.dart';

/// Which key the backend's `GET /app-version` knows this app by.
const String kAppUpdateAppKey = 'parent';

/// Debug builds skip the check so development isn't interrupted; run with
/// `--dart-define=APP_UPDATE_CHECK_IN_DEBUG=true` to exercise it locally.
const bool kAppUpdateCheckInDebug = bool.fromEnvironment('APP_UPDATE_CHECK_IN_DEBUG');

enum AppUpdateKind { none, optional, force }

/// Server answer for this app + platform (public endpoint, no auth, no school).
class AppVersionInfo {
  const AppVersionInfo({required this.latestVersion, required this.minVersion, required this.storeUrl, this.message});

  final String latestVersion;
  final String minVersion;
  final String storeUrl;
  final String? message;

  factory AppVersionInfo.fromJson(Map<String, dynamic> j) => AppVersionInfo(
        latestVersion: j['latestVersion'] as String,
        minVersion: j['minVersion'] as String,
        storeUrl: j['storeUrl'] as String,
        message: (j['message'] as String?)?.trim().isEmpty ?? true ? null : (j['message'] as String).trim(),
      );
}

/// Numeric, part-by-part compare of dotted versions: "1.0.10" > "1.0.9". Throws [FormatException] on a non-numeric
/// part (callers fail open). A missing part counts as 0, so "1.0" == "1.0.0".
int compareVersions(String a, String b) {
  final pa = a.split('.').map(int.parse).toList();
  final pb = b.split('.').map(int.parse).toList();
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}

AppUpdateKind decideUpdate(String current, AppVersionInfo info) {
  if (compareVersions(current, info.minVersion) < 0) return AppUpdateKind.force;
  if (compareVersions(current, info.latestVersion) < 0) return AppUpdateKind.optional;
  return AppUpdateKind.none;
}

/// Checks the public `/app-version` endpoint and shows a force / optional update dialog. FAIL OPEN: any network, parse,
/// timeout or 404 problem means "do nothing" - this must never block the app.
class AppUpdateService extends GetxService with WidgetsBindingObserver {
  AppUpdateService(this._client);

  final BaseClient _client;

  static const _timeout = Duration(seconds: 5);
  static const _minRecheck = Duration(hours: 6);
  static const _defaultMessage = 'A new version of Eldermin is available. Please update to continue.';

  DateTime? _lastCheckedAt;
  bool _checking = false;
  bool _dialogShowing = false;
  final Set<String> _laterForVersions = {};

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastCheckedAt;
    if (last == null || DateTime.now().difference(last) >= _minRecheck) checkForUpdate();
  }

  /// Safe to call any time; never throws.
  Future<void> checkForUpdate() async {
    if (kDebugMode && !kAppUpdateCheckInDebug) return;
    if (_checking || _dialogShowing) return;
    _checking = true;
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final current = (await PackageInfo.fromPlatform()).version;
      // requiresAuth:false -> no Authorization header; this app sends no school/tenant headers at all.
      final res = await _client
          .get(
            '${ApiConstants.apiPrefix}/app-version',
            queryParameters: {'app': kAppUpdateAppKey, 'platform': platform},
            requiresAuth: false,
          )
          .timeout(_timeout);
      _lastCheckedAt = DateTime.now();
      final info = AppVersionInfo.fromJson(Map<String, dynamic>.from(res.data as Map));
      switch (decideUpdate(current, info)) {
        case AppUpdateKind.force:
          await _showDialog(info, force: true);
        case AppUpdateKind.optional:
          if (!_laterForVersions.contains(info.latestVersion)) await _showDialog(info, force: false);
        case AppUpdateKind.none:
          break;
      }
    } catch (e) {
      AppLog.d('App update check skipped: $e');
    } finally {
      _checking = false;
    }
  }

  Future<void> _showDialog(AppVersionInfo info, {required bool force}) async {
    if (_dialogShowing || Get.context == null) return; // never stack two dialogs
    _dialogShowing = true;
    try {
      final message = info.message ?? (force ? _defaultMessage : 'A new version of Eldermin is available.');
      // Forced: the Update button never closes it, so coming back from the store un-updated lands on it again.
      final update = await Get.dialog<bool>(
        PopScope(
          canPop: !force,
          child: EmDialog(
            title: force ? 'Update required' : 'Update available',
            message: message,
            actions: [
              if (!force) EmDialogAction(label: 'Later', onPressed: () => Get.back(result: false)),
              EmDialogAction(
                label: 'Update',
                tone: EmDialogTone.primary,
                onPressed: () {
                  _openStore(info.storeUrl);
                  if (!force) Get.back(result: true);
                },
              ),
            ],
          ),
        ),
        barrierDismissible: !force,
      );
      if (!force && update != true) _laterForVersions.add(info.latestVersion);
    } finally {
      _dialogShowing = false;
    }
  }

  Future<void> _openStore(String storeUrl) async {
    try {
      if (Platform.isAndroid) {
        final pkg = (await PackageInfo.fromPlatform()).packageName;
        if (await launchUrl(Uri.parse('market://details?id=$pkg'), mode: LaunchMode.externalApplication)) return;
      }
    } catch (_) {
      // No Play Store app / market:// unsupported - fall through to the https link.
    }
    try {
      await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLog.d('Could not open store: $e');
    }
  }
}
