import 'dart:async';
import 'package:eldermin_parent_app/app/components/custom_button.dart';
import 'package:eldermin_parent_app/app/components/custom_text_field.dart';
import 'package:eldermin_parent_app/app/components/custom_text.dart';
import 'package:eldermin_parent_app/app/modules/diary/controllers/diary_controller.dart';
import 'package:eldermin_parent_app/app/modules/home_tasks/controllers/home_tasks_controller.dart';
import 'package:eldermin_parent_app/app/modules/more/views/more_screen.dart';
import 'package:eldermin_parent_app/app/modules/quizzes/controllers/quiz_attempt_controller.dart';
import 'package:eldermin_parent_app/app/modules/quizzes/controllers/quizzes_controller.dart';
import 'package:eldermin_parent_app/app/modules/results/controllers/results_controller.dart';
import 'package:eldermin_parent_app/app/modules/results/views/results_screen.dart';
import 'package:eldermin_parent_app/app/modules/tarbiyah/controllers/tarbiyah_controller.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/widgets/app_widgets.dart';
import 'package:eldermin_parent_app/core/widgets/locked_feature_view.dart';
import 'package:eldermin_parent_app/core/widgets/shimmer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/p4_fixtures.dart';
import '../support/route_harness.dart';

/// P4: the remaining pushed screens (layout only) in every state at 390 dp and 320 dp @1.3x, the locked-state precedence and
/// lock copy, the quiz attempt, and the CustomButton / CustomTextField wrappers.
final screens = <String, (String, Object?)>{
  'diary': (Routes.diary, null),
  'courses': (Routes.courses, null),
  'quizzes': (Routes.quizzes, null),
  'quiz attempt': (Routes.quizAttempt, {'assessmentId': 'a1', 'subject': 'Mathematics', 'title': 'Fractions quiz'}),
  'learning resources': (Routes.learningResources, null),
  'library': (Routes.library, null),
  'tarbiyah': (Routes.tarbiyah, null),
  'home tasks': (Routes.homeTasks, null),
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

Future<void> _open(WidgetTester t, String route, Object? args, {double w = 390, double h = 844, double scale = 1}) async {
  await pumpApp(t, width: w, height: h, textScale: scale);
  unawaited(Get.toNamed(route, arguments: args));
  await settle(t);
}

const lockTitle = 'This feature is currently paused';
const lockBody = 'Please contact the school office for assistance.';

void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  group('every converted screen', () {
    for (final e in screens.entries) {
      for (final (w, h, scale) in [(390.0, 844.0, 1.0), (320.0, 640.0, 1.3)]) {
        testWidgets('${e.key}: data at ${w}dp @${scale}x, one title, no week strip, no tiny text', (t) async {
          setUpRouteDeps(p4Api());
          await _open(t, e.value.$1, e.value.$2, w: w, h: h, scale: scale);
          expect(find.byType(EmAppBar), findsOneWidget);
          expect(find.byType(EmDateStrip), findsNothing);
          expect(t.takeException(), isNull);
          // nothing is drawn below the kit's smallest type size (12 sp)
          for (final text in t.widgetList<Text>(find.byType(Text))) {
            final size = text.style?.fontSize;
            if (size != null) expect(size, greaterThanOrEqualTo(12), reason: '"${text.data}" is $size sp');
          }
          await disposeApp(t);
        });
      }

      testWidgets('${e.key}: loading, failed and empty answers render without overflow', (t) async {
        final hold = Completer<dynamic>();
        setUpRouteDeps(p4Api(hold: hold));
        await _open(t, e.value.$1, e.value.$2, w: 320, h: 640, scale: 1.3);
        expect(t.takeException(), isNull, reason: 'loading');
        hold.complete(<dynamic>[]);
        await settle(t);
        await disposeApp(t);

        setUpRouteDeps((m, url) => throw networkError(url));
        await _open(t, e.value.$1, e.value.$2, w: 320, h: 640, scale: 1.3);
        expect(t.takeException(), isNull, reason: 'error');
        await disposeApp(t);

        setUpRouteDeps(p4Api(empty: true));
        await _open(t, e.value.$1, e.value.$2, w: 320, h: 640, scale: 1.3);
        expect(t.takeException(), isNull, reason: 'empty');
        await disposeApp(t);
      });
    }
  });

  group('locked-aware screens keep loading -> error -> locked -> data and the lock copy', () {
    final cases = <String, (String?, Object?, Widget?, Object Function() controller)>{
      'results (Progress tab)': (null, null, const ResultsScreen(), () => Get.find<ResultsController>()),
      'tarbiyah': (Routes.tarbiyah, null, null, () => Get.find<TarbiyahController>()),
      'class diary': (Routes.diary, null, null, () => Get.find<DiaryController>()),
      'quizzes': (Routes.quizzes, null, null, () => Get.find<QuizzesController>()),
      'quiz attempt': (Routes.quizAttempt, {'assessmentId': 'a1', 'subject': 'Maths', 'title': 'Q'}, null, () => Get.find<QuizAttemptController>()),
      'home tasks': (Routes.homeTasks, null, null, () => Get.find<HomeTasksController>()),
    };

    for (final c in cases.entries) {
      testWidgets('${c.key}: precedence and copy', (t) async {
        // empty answers, so the "loading and nothing yet" condition of each screen can hold
        setUpRouteDeps(p4Api(empty: true));
        if (c.value.$3 != null) {
          await pumpApp(t, home: Scaffold(body: c.value.$3));
          await settle(t);
        } else {
          await _open(t, c.value.$1!, c.value.$2);
        }
        dynamic ctl = c.value.$4();
        final loader = find.byWidgetPredicate((w) => w is AppShimmer || w is CircularProgressIndicator);

        // loading wins over error and locked
        ctl.loading.value = true;
        ctl.error.value = 'boom';
        ctl.locked.value = true;
        await t.pump();
        expect(loader, findsWidgets, reason: 'loading first');
        expect(find.byType(AppErrorView), findsNothing);
        expect(find.byType(LockedFeatureView), findsNothing);

        // then error wins over locked
        ctl.loading.value = false;
        await t.pump();
        expect(find.byType(AppErrorView), findsOneWidget, reason: 'error before locked');
        expect(find.text('boom'), findsOneWidget);
        expect(find.byType(LockedFeatureView), findsNothing);

        // then locked: exactly the calm copy, no retry, no reason
        ctl.error.value = null;
        await t.pump();
        expect(find.byType(LockedFeatureView), findsOneWidget);
        expect(find.text(lockTitle), findsOneWidget);
        expect(find.text(lockBody), findsOneWidget);
        expect(find.text('Try again'), findsNothing);
        expect(find.byType(AppErrorView), findsNothing);

        // and data when it is neither
        ctl.locked.value = false;
        await t.pump();
        expect(find.byType(LockedFeatureView), findsNothing);
        expect(find.byType(AppErrorView), findsNothing);
        expect(loader, findsNothing);
        await disposeApp(t);
      });
    }

    testWidgets('lock copy is the same at 320 dp @1.3x and uses the kit empty state', (t) async {
      setUpRouteDeps((m, url) => suspendedBody);
      await _open(t, Routes.diary, null, w: 320, h: 640, scale: 1.3);
      expect(find.byType(EmEmptyState), findsOneWidget);
      expect(find.text(lockTitle), findsOneWidget);
      expect(find.text(lockBody), findsOneWidget);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });
  });

  group('quiz attempt (layout only; the controller is untouched)', () {
    final args = {'assessmentId': 'a1', 'subject': 'Mathematics', 'title': 'Fractions quiz'};

    testWidgets('there is no timer today: nothing counts down and no time limit auto-submits', (t) async {
      final client = setUpRouteDeps(p4Api());
      await _open(t, Routes.quizAttempt, args);
      expect(find.text('Question 1 of 3'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\b\d{1,2}:\d{2}\b')), findsNothing, reason: 'no clock / countdown');
      expect(find.textContaining(RegExp('time left|remaining|timer', caseSensitive: false)), findsNothing);
      // an hour later the attempt is still open and nothing was submitted
      await t.pump(const Duration(hours: 1));
      expect(client.calls.where((c) => c.contains('/submit')), isEmpty);
      expect(find.text('Question 1 of 3'), findsOneWidget);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('an answer persists across question changes and rebuilds', (t) async {
      setUpRouteDeps(p4Api());
      await _open(t, Routes.quizAttempt, args);
      await t.tap(find.text('1'));
      await settle(t);
      final ctl = Get.find<QuizAttemptController>();
      expect(ctl.answers['q1']!['selectedOptionIndex'], 1);
      // Next -> True/False question -> answer -> Previous: the first answer is still selected
      await t.tap(find.text('Next'));
      await settle(t);
      expect(find.text('Question 2 of 3'), findsOneWidget);
      await t.tap(find.text('True'));
      await settle(t);
      await t.tap(find.text('Previous'));
      await settle(t);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(ctl.answers['q1']!['selectedOptionIndex'], 1);
      // a layout change (text scale / size) rebuilds the screen: still selected
      t.view.physicalSize = const Size(320, 640);
      await t.pump();
      await settle(t);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(ctl.answers.length, 2);
      // and the short answer keeps its text when the question is left and re-entered
      await t.tap(find.text('Next'));
      await settle(t);
      await t.tap(find.text('Next'));
      await settle(t);
      await t.enterText(find.byType(TextFormField), 'numerator');
      await t.tap(find.text('Previous'));
      await settle(t);
      await t.tap(find.text('Next'));
      await settle(t);
      expect(find.text('numerator'), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('submit asks first, posts the answers once, ignores taps while it runs, then shows the result', (t) async {
      final submit = Completer<dynamic>();
      final client = setUpRouteDeps((m, url) {
        if (url.endsWith('/submit')) return submit.future;
        return p4Api()(m, url);
      });
      await _open(t, Routes.quizAttempt, args);
      await t.tap(find.text('1'));
      await t.tap(find.text('Next'));
      await settle(t);
      await t.tap(find.text('Next'));
      await settle(t);
      expect(find.text('Submit (1/3)'), findsOneWidget);
      await t.tap(find.text('Submit (1/3)'));
      await settle(t);
      // the confirmation (kit dialog) names the unanswered questions; Review closes it without posting
      expect(find.byType(EmDialog), findsOneWidget);
      expect(find.textContaining('2 question(s) are unanswered'), findsOneWidget);
      await t.tap(find.text('Review'));
      await settle(t);
      expect(client.calls.where((c) => c.contains('/submit')), isEmpty);
      await t.tap(find.text('Submit (1/3)'));
      await settle(t);
      await t.tap(find.descendant(of: find.byType(EmDialog), matching: find.text('Submit')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(client.calls.where((c) => c.startsWith('POST') && c.contains('/submit')).length, 1);
      // while the request runs the button is a spinner and does not post again
      expect(Get.find<QuizAttemptController>().submitting.value, isTrue);
      await t.tapAt(t.getCenter(find.byType(EmMorphButton).last));
      await t.pump(const Duration(milliseconds: 300));
      expect(client.calls.where((c) => c.startsWith('POST') && c.contains('/submit')).length, 1);
      submit.complete({'status': 'graded', 'totalMarks': 3, 'passingMarks': 1, 'obtainedMarks': 2});
      await settle(t);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('Well done - you passed!'), findsOneWidget);
      expect(find.text('Back to quizzes'), findsOneWidget);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });
  });

  group('CustomButton wraps the kit button', () {
    Future<void> pump(WidgetTester t, Widget w) async {
      setUpRouteDeps(p4Api());
      await pumpApp(t, home: Scaffold(body: Padding(padding: const EdgeInsets.all(20), child: w)));
    }

    testWidgets('enabled: taps call onPressed once; it is an EmMorphButton', (t) async {
      var taps = 0;
      await pump(t, CustomButton(label: 'Save', onPressed: () => taps++));
      expect(find.byType(EmMorphButton), findsOneWidget);
      await t.tap(find.text('Save'));
      await t.pump(const Duration(milliseconds: 300));
      expect(taps, 1);
      await disposeApp(t);
    });

    testWidgets('disabled: dimmed and not tappable', (t) async {
      var taps = 0;
      await pump(t, CustomButton(label: 'Save', enabled: false, onPressed: () => taps++));
      expect(t.widget<EmMorphButton>(find.byType(EmMorphButton)).onPressed, isNull);
      await t.tap(find.text('Save'), warnIfMissed: false);
      expect(taps, 0);
      expect(t.widget<Opacity>(find.descendant(of: find.byType(EmMorphButton), matching: find.byType(Opacity)).first).opacity, lessThan(1));
      await disposeApp(t);
    });

    testWidgets('loading (empty label + spinner prefix, as every call site does): a spinner, taps ignored', (t) async {
      var taps = 0;
      await pump(t, CustomButton(label: '', prefix: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()), onPressed: () => taps++));
      await t.pump(const Duration(milliseconds: 400));
      expect(t.widget<EmMorphButton>(find.byType(EmMorphButton)).phase, EmMorphPhase.loading);
      await t.tap(find.byType(EmMorphButton), warnIfMissed: false);
      expect(taps, 0);
      await disposeApp(t);
    });

    testWidgets('width is honoured, otherwise the button fills the available width', (t) async {
      await pump(t, CustomButton(label: 'Wide', onPressed: () {}));
      expect(t.getSize(find.byType(EmMorphButton)).width, greaterThan(300));
      await disposeApp(t);
      await pump(t, CustomButton(label: 'Narrow', width: 120, onPressed: () {}));
      expect(t.getSize(find.byType(CustomButton)).width, 120);
      await disposeApp(t);
    });
  });

  group('CustomTextField wraps the kit field', () {
    testWidgets('label, hint fallback, controller, onChanged, errorText, obscure, maxLength and validator all work', (t) async {
      setUpRouteDeps(p4Api());
      final c = TextEditingController();
      final changes = <String>[];
      final formKey = GlobalKey<FormState>();
      await pumpApp(
        t,
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(children: [
              CustomTextField(controller: c, label: 'Subject', hintText: 'Short title', maxLength: 5, onChanged: changes.add, validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
              const CustomTextField(hintText: 'Only a hint'),
              const CustomTextField(label: 'Secret', obscureText: true, errorText: 'Too short'),
            ]),
          ),
        ),
      );
      expect(find.byType(EmTextField), findsNWidgets(3));
      expect(find.text('Subject'), findsOneWidget);
      expect(find.text('Only a hint'), findsOneWidget, reason: 'no label -> the hint becomes the label');
      expect(find.text('Too short'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await t.pump();
      expect(find.text('Required'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, 'abcdefgh');
      expect(c.text, 'abcde', reason: 'maxLength limits the input');
      expect(changes.last, 'abcde');
      expect(formKey.currentState!.validate(), isTrue);
      expect(t.widget<TextField>(find.byType(TextField).last).obscureText, isTrue);
      await disposeApp(t);
    });
  });

  group('CustomText snaps to the kit type scale', () {
    for (final (asked, expected) in [(9.0, 12.0), (11.5, 12.0), (12.0, 12.0), (12.5, 13.0), (14.0, 14.0), (15.0, 14.0), (16.0, 16.0), (20.0, 18.0), (28.0, 22.0)]) {
      testWidgets('a request for $asked sp renders at $expected sp', (t) async {
        setUpRouteDeps(p4Api());
        await pumpApp(t, home: Scaffold(body: CustomText(text: 'Hello', fontSize: asked, fontWeight: FontWeight.w700)));
        final style = t.widget<Text>(find.text('Hello')).style!;
        expect(style.fontSize, expected);
        expect(style.fontFamily, EmType.family);
        expect(style.fontWeight, FontWeight.w700);
        await disposeApp(t);
      });
    }
  });

  group('More: the 22 services in sections', () {
    testWidgets('same tiles and destinations, grouped; the Early Years spot is only a comment', (t) async {
      setUpRouteDeps(p4Api());
      await pumpApp(t, home: const Scaffold(body: MoreScreen()));
      await settle(t);
      final list = find.byType(Scrollable).first;
      final headings = ['Quick access', 'Learning', 'My child', 'School & family', 'Account'];
      for (final h in headings) {
        await t.scrollUntilVisible(find.text(h), 300, scrollable: list);
        expect(find.text(h), findsOneWidget, reason: h);
      }
      // 22 services in the four groups, none lost, none added
      final services = ['Class diary', 'My courses', 'Online quizzes', 'Learning resources', 'Library', 'Datesheet', 'Behaviour & Tarbiyah', 'Student profile', 'Medical', 'Academic documents', 'Home tasks', 'Consent', 'My leaves', 'Parent-teacher meetings', 'Circulars', 'Inbox', 'Feedback', 'Switch user', 'Privacy policy', 'About us', 'Help', 'Logout'];
      expect(services.length, 22);
      var seen = 0;
      for (final s in services) {
        await t.scrollUntilVisible(find.byKey(Key('service_$s')), 300, scrollable: list);
        seen++;
      }
      expect(seen, 22);
      expect(find.byKey(const Key('service_Early Years')), findsNothing);
      // order inside a group is the old order
      await t.scrollUntilVisible(find.byKey(const Key('service_Class diary')), -300, scrollable: list);
      double y(String s) => t.getTopLeft(find.byKey(Key('service_$s'))).dy;
      expect(y('Class diary'), lessThanOrEqualTo(y('Online quizzes')));
      await disposeApp(t);
    });
  });
}
