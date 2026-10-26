@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/p4_fixtures.dart';
import '../support/route_harness.dart';

/// Goldens of the P4 screens at 390x844, text scale 1.0 and 1.3. Deterministic (the clock and the controllers' month /
/// weekday are pinned in `test/support/route_harness.dart`), exact comparison, macOS baselines (other hosts skip).
///
///   Update:  flutter test test/design/p4_goldens_test.dart --tags golden --update-goldens
void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);
  final skip = Platform.isMacOS ? null : 'goldens are macOS baselines';

  final screens = <String, (String, Object?)>{
    'diary': (Routes.diary, null),
    'courses': (Routes.courses, null),
    'quizzes': (Routes.quizzes, null),
    'quiz_attempt': (Routes.quizAttempt, {'assessmentId': 'a1', 'subject': 'Mathematics', 'title': 'Fractions quiz'}),
    'learning_resources': (Routes.learningResources, null),
    'library': (Routes.library, null),
    'tarbiyah': (Routes.tarbiyah, null),
    'home_tasks': (Routes.homeTasks, null),
    'datesheet': (Routes.datesheet, null),
    'circulars': (Routes.circulars, null),
    'consent': (Routes.consent, null),
    'medical': (Routes.medical, null),
    'documents': (Routes.documents, null),
    'feedback': (Routes.feedback, null),
    'about': (Routes.aboutUs, null),
    'help': (Routes.help, null),
    'privacy': (Routes.privacyPolicy, null),
  };

  for (final scale in [1.0, 1.3]) {
    final tag = scale == 1.0 ? 'normal' : 'scale13';
    for (final e in screens.entries) {
      testWidgets('${e.key} / $tag', (t) async {
        setUpRouteDeps(p4Api());
        await pumpApp(t, textScale: scale);
        unawaited(Get.toNamed(e.value.$1, arguments: e.value.$2));
        await settle(t);
        await expectLater(find.byType(EmScaffold).last, matchesGoldenFile('goldens/p4/${e.key}_$tag.png'));
        await disposeApp(t);
      }, skip: skip != null);
    }
  }
}
