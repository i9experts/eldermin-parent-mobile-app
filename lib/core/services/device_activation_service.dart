import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'app_preferences.dart';
import 'parent_api_service.dart';

/// Pings the backend with a stable, locally generated device id on every
/// login and every app cold start, so Eldermin's school-admin dashboard
/// can report real device/activation counts instead of a single
/// overwritten login timestamp. No Firebase, no push setup, no store
/// APIs - just a value this app already generates and keeps locally.
///
/// Deliberately fire-and-forget: a failed ping (offline, server hiccup)
/// must never block login or delay app startup, so every call here
/// swallows its own errors.
class DeviceActivationService {
  final ParentApiService _api;
  DeviceActivationService(this._api);

  Future<void> pingNow() async {
    try {
      final deviceId = await AppPreferences.getOrCreateDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';
      String? appVersion;
      try {
        appVersion = (await PackageInfo.fromPlatform()).version;
      } catch (_) {
        // Non-essential - the ping is still worth sending without it.
      }
      await _api.pingDevice(deviceId: deviceId, platform: platform, appVersion: appVersion);
    } catch (_) {
      // Silently ignored by design - see class doc.
    }
  }
}
