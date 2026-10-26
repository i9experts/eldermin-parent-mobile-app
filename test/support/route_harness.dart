import 'dart:async';
import 'package:dio/dio.dart';
import 'package:eldermin_parent_app/app/modules/auth/controllers/auth_controller.dart';
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

  Future<Response<T>> _answer<T>(String method, String url) async {
    calls.add('$method $url');
    final body = await respond(method, url);
    return Response<T>(requestOptions: RequestOptions(path: url), data: body as T?, statusCode: 200);
  }

  @override
  Future<Response> get(String url, {Map<String, dynamic>? queryParameters, bool requiresAuth = true}) => _answer('GET', url);

  @override
  Future<Response> post(String url, {data, Map<String, dynamic>? queryParameters, bool requiresAuth = true}) => _answer('POST', url);

  @override
  Future<Response> patch(String url, {data, Map<String, dynamic>? queryParameters, bool requiresAuth = true}) => _answer('PATCH', url);
}

DioException networkError(String url) => DioException(requestOptions: RequestOptions(path: url), type: DioExceptionType.connectionError);

/// The suspended-feature placeholder (HTTP 200) the backend sends for a paused premium feature.
const suspendedBody = {'suspended': true, 'feature': 'paused', 'reason': 'paused by the school'};

final testStudent = Student(id: 's1', firstName: 'Ayesha', lastName: 'Khan', currentGrade: 'Grade 5', currentSection: 'A', admissionNo: '1001');

/// Registers the app's global singletons on a fake API, exactly like InitialBinding but with no storage/network.
FakeClient setUpRouteDeps(FutureOr<dynamic> Function(String method, String url) respond, {bool withStudent = true}) {
  EmAuthPhotos.precacheImpl = (_, __) async {};
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
  }
}

/// Tears the screen down so periodic timers (OTP resend) are cancelled before the test ends.
Future<void> disposeApp(WidgetTester t) async {
  await t.pump(const Duration(seconds: 3)); // error toasts hold a 2 s timer
  await t.pumpWidget(const SizedBox());
  Get.reset();
}
