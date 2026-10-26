import 'dart:async';
import 'package:dio/dio.dart';
import 'package:eldermin_parent_app/app/modules/attendance/controllers/attendance_controller.dart';
import 'package:eldermin_parent_app/app/modules/auth/controllers/auth_controller.dart';
import 'package:eldermin_parent_app/app/modules/circulars/controllers/circulars_controller.dart';
import 'package:eldermin_parent_app/app/modules/events/controllers/events_controller.dart';
import 'package:eldermin_parent_app/app/modules/homework/controllers/homework_controller.dart';
import 'package:eldermin_parent_app/app/modules/library/controllers/library_controller.dart';
import 'package:eldermin_parent_app/app/modules/timetable/controllers/timetable_controller.dart';
import 'package:eldermin_parent_app/core/utils/greeting.dart';
import 'package:eldermin_parent_app/app/modules/students/controllers/student_controller.dart';
import 'package:eldermin_parent_app/app/routes/app_pages.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/models/student.dart';
import 'package:eldermin_parent_app/core/network/base_client.dart';
import 'package:eldermin_parent_app/core/services/parent_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'auth_harness.dart';

/// Answers every API call from [respond] (method, url) -> decoded body. Throw a [DioException] to simulate a failure,
/// or return a Future that never completes to hold a screen in its loading state. No network is ever touched.
class FakeClient extends BaseClient {
  FakeClient(this.respond);
  final FutureOr<dynamic> Function(String method, String url) respond;
  final calls = <String>[];

  /// Every request with the body it carried (null for a GET), in order.
  final requests = <({String method, String url, dynamic data})>[];

  /// The bodies POSTed to a url ending with [suffix].
  List<dynamic> postedTo(String suffix) => [for (final r in requests) if (r.method == 'POST' && r.url.endsWith(suffix)) r.data];

  Future<Response<T>> _answer<T>(String method, String url, [dynamic data]) async {
    calls.add('$method $url');
    requests.add((method: method, url: url, data: data));
    final body = await respond(method, url);
    return Response<T>(requestOptions: RequestOptions(path: url), data: body as T?, statusCode: 200);
  }

  @override
  Future<Response> get(String url, {Map<String, dynamic>? queryParameters, bool requiresAuth = true}) => _answer('GET', url);

  @override
  Future<Response> post(String url, {data, Map<String, dynamic>? queryParameters, bool requiresAuth = true}) => _answer('POST', url, data);

  @override
  Future<Response> patch(String url, {data, Map<String, dynamic>? queryParameters, bool requiresAuth = true}) => _answer('PATCH', url, data);
}

DioException networkError(String url) => DioException(requestOptions: RequestOptions(path: url), type: DioExceptionType.connectionError);

/// The suspended-feature placeholder (HTTP 200) the backend sends for a paused premium feature.
const suspendedBody = {'suspended': true, 'feature': 'paused', 'reason': 'paused by the school'};

/// Monday 26 October 2026, 09:30: the pinned "now" of every screen test and golden.
final pinnedNow = DateTime(2026, 10, 26, 9, 30);
final _pinned = <Object>{};

final testStudent = Student(id: 's1', firstName: 'Ayesha', lastName: 'Khan', currentGrade: '5', currentSection: 'A', admissionNo: '1001');

/// Registers the app's global singletons on a fake API, exactly like InitialBinding but with no storage/network.
FakeClient setUpRouteDeps(FutureOr<dynamic> Function(String method, String url) respond, {bool withStudent = true}) {
  EmAuthPhotos.precacheImpl = (_, __) async {};
  uiNow = () => pinnedNow;
  _pinned.clear();
  Get.reset();
  Get.testMode = true;
  final client = FakeClient(respond);
  final api = ParentApiService(client);
  Get.put<ParentApiService>(api, permanent: true);
  Get.put<AuthController>(StubAuth()..status.value = AuthStatus.authenticated, permanent: true);
  final students = StudentController(api);
  if (withStudent) students.students.value = [testStudent];
  Get.put<StudentController>(students, permanent: true);
  return client;
}

Future<void> pumpApp(WidgetTester t, {Widget? home, double width = 390, double height = 844, double textScale = 1}) async {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildEmTheme(),
    getPages: AppPages.pages,
    builder: (context, c) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: c!),
    home: home ?? const Scaffold(body: SizedBox.expand()),
  ));
}

/// Pushes [route] on a bare app (with its real binding) and lets it load.
Future<void> pumpRoute(WidgetTester t, String route, {Object? arguments, double textScale = 1}) async {
  await pumpApp(t, textScale: textScale);
  unawaited(Get.toNamed(route, arguments: arguments));
  await settle(t);
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 250));
    _pinDates();
  }
}

/// The controllers start their month / weekday selection from the wall clock; once each exists, pin it (once) to the
/// pinned date so month filters, labels and goldens are deterministic. Test-only: no controller code is involved.
void _pinDates() {
  void once(Object c, void Function() pin) {
    if (_pinned.add(c)) pin();
  }

  final month = DateTime(pinnedNow.year, pinnedNow.month);
  if (Get.isRegistered<AttendanceController>()) {
    final c = Get.find<AttendanceController>();
    once(c, () => c.selectedMonth.value = month);
  }
  if (Get.isRegistered<HomeworkController>()) {
    final c = Get.find<HomeworkController>();
    once(c, () => c.selectedMonth.value = month);
  }
  if (Get.isRegistered<EventsController>()) {
    final c = Get.find<EventsController>();
    once(c, () => c.selectedMonth.value = month);
  }
  if (Get.isRegistered<LibraryController>()) {
    final c = Get.find<LibraryController>();
    once(c, () => c.selectedMonth.value = month);
  }
  if (Get.isRegistered<CircularsController>()) {
    final c = Get.find<CircularsController>();
    once(c, () => c.selectedMonth.value = month);
  }
  if (Get.isRegistered<TimetableController>()) {
    final c = Get.find<TimetableController>();
    once(c, () => c.selectedDay.value = pinnedNow.weekday - 1);
  }
}

/// Tears the screen down so periodic timers (OTP resend) are cancelled before the test ends.
Future<void> disposeApp(WidgetTester t) async {
  uiNow = DateTime.now;
  await t.pump(const Duration(seconds: 3)); // error toasts hold a 2 s timer
  await t.pumpWidget(const SizedBox());
  Get.reset();
}
