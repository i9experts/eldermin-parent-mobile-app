import 'package:flutter/foundation.dart';

/// The only way app code writes to the console. Output is dropped in
/// profile/release builds so request paths, error bodies and anything
/// else that might carry tokens, OTPs, phone numbers or student data
/// never reaches device logs (logcat / Console.app).
class AppLog {
  AppLog._();

  /// Overridable so tests can flip the gate and capture output.
  @visibleForTesting
  static bool enabled = kDebugMode;

  @visibleForTesting
  static void Function(String message) sink = _print;

  static void _print(String message) => debugPrint(message);

  static void d(String message) {
    if (!enabled) return;
    sink(message);
  }
}
