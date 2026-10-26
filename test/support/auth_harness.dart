import 'dart:io';
import 'package:eldermin_parent_app/app/modules/auth/controllers/auth_controller.dart';
import 'package:eldermin_parent_app/app/modules/auth/controllers/otp_verify_controller.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/network/api_exception.dart';
import 'package:eldermin_parent_app/core/network/base_client.dart';
import 'package:eldermin_parent_app/core/services/parent_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Loads the bundled Plus Jakarta Sans (flutter_test otherwise uses the wide "Ahem" font) and the icon font.
Future<void> loadAuthFonts() async {
  final loader = FontLoader('PlusJakartaSans');
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final b = File('assets/fonts/PlusJakartaSans-$f.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(b).buffer)));
  }
  await loader.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final f = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (f.existsSync()) {
      final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(Uint8List.fromList(f.readAsBytesSync()).buffer)));
      await icons.load();
    }
  }
}

/// The session controller without its bootstrap (no storage, no 3 s splash hold).
class StubAuth extends AuthController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

/// No network is ever called: the OTP request answers from here.
class FakeApi extends ParentApiService {
  FakeApi() : super(BaseClient());
  final otpCalls = <String>[];
  ApiException? otpError;
  Map<String, dynamic> otpResult = {'sent': true, 'devCode': null};

  @override
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    otpCalls.add(phone);
    if (otpError != null) throw otpError!;
    return otpResult;
  }
}

FakeApi setUpAuthDeps() {
  EmAuthPhotos.precacheImpl = (_, __) async {}; // widget tests cannot decode the photos; they stay navy
  Get.reset();
  Get.testMode = true;
  final api = FakeApi();
  Get.put<ParentApiService>(api);
  Get.put<AuthController>(StubAuth()..status.value = AuthStatus.unauthenticated);
  return api;
}

/// Pumps [screen] full-screen at [width] x [height], with text scale, direction and a simulated keyboard.
Future<void> pumpScreen(
  WidgetTester t,
  Widget screen, {
  double width = 390,
  double height = 844,
  double textScale = 1,
  TextDirection dir = TextDirection.ltr,
  double keyboard = 0,
  double topInset = 47,
  double bottomInset = 34,
  bool reduce = false,
}) async {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildEmTheme(), // the real app theme
    builder: (context, c) => Directionality(
      textDirection: dir,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduce,
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: keyboard),
          padding: EdgeInsets.only(top: topInset, bottom: keyboard > 0 ? 0 : bottomInset),
        ),
        child: c!,
      ),
    ),
    home: screen,
  ));
  await t.pump(const Duration(milliseconds: 1200));
}

/// Decodes the real auth photos into the image cache (goldens show them; most tests leave them out).
Future<void> loadAuthPhotos(WidgetTester t) async {
  final context = t.element(find.byType(GetMaterialApp));
  await t.runAsync(() async {
    for (final a in EmAuthPhotos.slides) {
      await precacheImage(AssetImage(a), context);
    }
  });
  await t.pump();
}

/// The OTP controller with its route arguments filled in (no timer, nothing to dispose).
class TestOtp extends OtpVerifyController {
  TestOtp({String? dev}) : _dev = dev;
  final String? _dev;
  @override
  // ignore: must_call_super
  void onInit() {
    phone = '+923001234567';
    devCode = _dev;
  }
}
