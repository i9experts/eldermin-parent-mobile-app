import 'dart:async';
import 'package:eldermin_parent_app/app/modules/results/views/results_screen.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/widgets/app_widgets.dart';
import 'package:eldermin_parent_app/core/widgets/locked_feature_view.dart';
import 'package:eldermin_parent_app/core/widgets/shimmer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/route_harness.dart';

/// The six screens that can be paused by the school (FeatureAccessResult.suspended) keep the same precedence:
/// loading, then error, then locked, then data. A paused feature shows only the calm LockedFeatureView.
class _Screen {
  _Screen(this.name, this.route, {this.args, this.dataBody, this.tab = false});
  final String name;
  final String? route; // null: a tab screen pumped directly
  final Object? args;
  final dynamic Function()? dataBody;
  final bool tab;
}

dynamic quizStart(String method, String url) => {
      'attempt': {'_id': 'att1'},
      'questions': [
        {
          '_id': 'q1',
          'type': 'mcq',
          'questionText': '1/2 + 1/2 = ?',
          'options': [{'text': '1'}, {'text': '2'}],
          'marks': 1,
        },
      ],
    };

dynamic _list() => <dynamic>[];
dynamic _map() => <String, dynamic>{};

final screens = [
  _Screen('results (Progress tab)', null, tab: true, dataBody: _list),
  _Screen('tarbiyah', Routes.tarbiyah, dataBody: _map),
  _Screen('class diary', Routes.diary, dataBody: _list),
  _Screen('quizzes', Routes.quizzes, dataBody: _list),
  _Screen('quiz attempt', Routes.quizAttempt, args: {'assessmentId': 'a1', 'subject': 'Maths', 'title': 'Fractions'}),
  _Screen('home tasks', Routes.homeTasks, dataBody: _list),
];

Finder get _loading => find.byWidgetPredicate((w) => w is AppShimmer || w is CircularProgressIndicator);

Future<void> _open(WidgetTester t, _Screen s) async {
  if (s.tab) {
    await pumpApp(t, home: const Scaffold(body: ResultsScreen()));
    await settle(t);
  } else {
    await pumpRoute(t, s.route!, arguments: s.args);
  }
}

void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  for (final s in screens) {
    group(s.name, () {
      testWidgets('loading: a skeleton / spinner only (no error, no lock)', (t) async {
        setUpRouteDeps((m, url) => Completer<dynamic>().future);
        await _open(t, s);
        expect(_loading, findsWidgets);
        expect(find.byType(AppErrorView), findsNothing);
        expect(find.byType(LockedFeatureView), findsNothing);
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });

      testWidgets('error: the error view with retry (not the lock)', (t) async {
        setUpRouteDeps((m, url) => throw networkError(url));
        await _open(t, s);
        expect(find.byType(AppErrorView), findsOneWidget);
        expect(_loading, findsNothing);
        expect(find.byType(LockedFeatureView), findsNothing);
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });

      testWidgets('locked: only the calm paused view, no data and no error', (t) async {
        setUpRouteDeps((m, url) => suspendedBody);
        await _open(t, s);
        expect(find.byType(LockedFeatureView), findsOneWidget);
        expect(find.text('This feature is currently paused'), findsOneWidget);
        expect(find.byType(AppErrorView), findsNothing);
        expect(find.byType(ScreenHeader), findsNothing);
        expect(_loading, findsNothing);
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });

      testWidgets('data: no lock and no error', (t) async {
        setUpRouteDeps(s.dataBody != null ? (m, url) => s.dataBody!() : quizStart);
        await _open(t, s);
        expect(find.byType(LockedFeatureView), findsNothing);
        expect(find.byType(AppErrorView), findsNothing);
        expect(_loading, findsNothing);
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });

      testWidgets('order: loading first, then the answer decides (locked)', (t) async {
        final answer = Completer<dynamic>();
        setUpRouteDeps((m, url) => answer.future);
        await _open(t, s);
        expect(_loading, findsWidgets);
        expect(find.byType(LockedFeatureView), findsNothing);
        answer.complete(suspendedBody);
        await settle(t);
        expect(find.byType(LockedFeatureView), findsOneWidget);
        expect(_loading, findsNothing);
        await disposeApp(t);
      });
    });
  }
}
