import 'package:eldermin_parent_app/core/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

AppVersionInfo info(String latest, String min) =>
    AppVersionInfo(latestVersion: latest, minVersion: min, storeUrl: 'https://x');

void main() {
  test('compares numerically, not as strings', () {
    expect(compareVersions('1.0.10', '1.0.9'), 1);
    expect(compareVersions('1.9.0', '1.10.0'), -1);
    expect(compareVersions('1.0', '1.0.0'), 0);
  });
  test('non-numeric version throws (caller fails open)', () {
    expect(() => compareVersions('1.0.x', '1.0.0'), throwsFormatException);
  });
  test('force / optional / none', () {
    expect(decideUpdate('1.0.5', info('1.0.9', '1.0.6')), AppUpdateKind.force);
    expect(decideUpdate('1.0.8', info('1.0.9', '0.0.0')), AppUpdateKind.optional);
    expect(decideUpdate('1.0.9', info('1.0.9', '0.0.0')), AppUpdateKind.none);
    expect(decideUpdate('1.0.10', info('1.0.9', '0.0.0')), AppUpdateKind.none);
  });
}
