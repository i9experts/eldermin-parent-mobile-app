import 'package:flutter_test/flutter_test.dart';
import 'package:eldermin_parent_app/core/utils/app_log.dart';

void main() {
  late bool originalEnabled;
  late void Function(String) originalSink;

  setUp(() {
    originalEnabled = AppLog.enabled;
    originalSink = AppLog.sink;
  });

  tearDown(() {
    AppLog.enabled = originalEnabled;
    AppLog.sink = originalSink;
  });

  test('writes nothing when logging is disabled (release/profile)', () {
    final out = <String>[];
    AppLog.sink = out.add;
    AppLog.enabled = false;

    AppLog.d('GET → /parent/students?phone=123');

    expect(out, isEmpty);
  });

  test('writes through when enabled (debug)', () {
    final out = <String>[];
    AppLog.sink = out.add;
    AppLog.enabled = true;

    AppLog.d('hello');

    expect(out, ['hello']);
  });

  test('defaults to the build mode', () {
    // Test runs are debug builds; a release build compiles this to false.
    expect(originalEnabled, isTrue);
  });
}
