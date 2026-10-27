// Dev tool (NOT shipped: lives under tool/). Runs the real parent app screens (splash, login, OTP) with a stubbed API and a SCRIPTED walkthrough, so the photo auth look can be recorded on the iOS
// simulator without UI automation:
//
//   tool/photo_auth/walk.sh UDID SCENARIO OUT_PREFIX      SCENARIO = a|b|d|e|f   (see _scenarios below)
//
// The script drives the screens through their own controllers (it types into the text controllers, calls the same
// methods the buttons call, pushes the same routes) and prints `MARK:<name>:<epoch ms>` lines that walk.sh uses to
// cut stills out of the recording. The keyboard is simulated (viewInsets + a grey panel), like the teacher walkthrough.
// The first mark, `flash`, is a magenta frame the recording is aligned on.
import 'dart:async';
import 'package:eldermin_parent_app/app/modules/auth/controllers/auth_controller.dart';
import 'package:eldermin_parent_app/app/modules/auth/controllers/phone_entry_controller.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/phone_entry_screen.dart';
import 'package:eldermin_parent_app/app/modules/splash/views/splash_screen.dart';
import 'package:eldermin_parent_app/app/routes/app_pages.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/network/base_client.dart';
import 'package:eldermin_parent_app/core/network/api_exception.dart';
import 'package:eldermin_parent_app/core/services/parent_api_service.dart';
import 'package:eldermin_parent_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore_for_file: avoid_print

const _walk = String.fromEnvironment('WALK', defaultValue: 'a');
const _keyboard = 336.0;

final _kb = ValueNotifier<double>(0);
final _flash = ValueNotifier<bool>(false);
const _reduce = _walk == 'e';
const _scale = _walk == 'f' ? 1.3 : 1.0;

void mark(String name) => print('MARK:$name:${DateTime.now().millisecondsSinceEpoch}');
Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

class _Api extends ParentApiService {
  _Api() : super(BaseClient());

  /// 0300 0000000 -> "not registered" error; anything else answers after 1.1 s with a dev code
  @override
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    await wait(1100);
    if (phone.endsWith('0000000')) throw ApiException('This number is not registered with any school.', statusCode: 404);
    return {'sent': true, 'devCode': '482913'};
  }
}

class _Binding extends Bindings {
  @override
  void dependencies() {
    Get.put<ParentApiService>(_Api(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}

/// Same switch as main.dart's `_AuthGate` (splash -> login), with the same crossfade.
class _Gate extends StatelessWidget {
  const _Gate();
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() => AnimatedSwitcher(
          duration: EmReduceMotion.of(context) ? EmMotion.crossfade : EmMotion.slow,
          child: KeyedSubtree(
              key: ValueKey(auth.status.value),
              child: auth.status.value == AuthStatus.unauthenticated ? const PhoneEntryScreen() : const SplashScreen()),
        ));
  }
}

Future<void> type(TextEditingController c, String text, {int perChar = 90}) async {
  for (var i = 1; i <= text.length; i++) {
    c.text = text.substring(0, i);
    await wait(perChar);
  }
}

Future<void> keyboard(bool up) async {
  _kb.value = up ? _keyboard : 0;
  await wait(700);
}

Future<void> script() async {
  await wait(100);
  _flash.value = true;
  await wait(250);
  mark('flash');
  _flash.value = false;
  switch (_walk) {
    case 'a': // splash (3 s hold) -> login
      for (final (n, ms) in [('a_splash_a', 150), ('a_splash_b', 250), ('a_splash_c', 300), ('a_splash_d', 500), ('a_splash_rings', 900)]) {
        await wait(ms);
        mark(n);
      }
      await wait(1200);
      mark('a_splash_holding');
      while (Get.find<AuthController>().status.value != AuthStatus.unauthenticated) {
        await wait(50);
      }
      await wait(120);
      mark('a_crossfade_start');
      await wait(160);
      mark('a_crossfade_mid');
      await wait(700);
      mark('a_login');
    case 'b': // login: keyboard, error + shake, valid number -> spinner -> OTP
    case 'e': // the same with reduce motion
    case 'f': // the same at text scale 1.3
      await _login(_walk);
  }
  await wait(800);
  mark('end');
  _flash.value = true;
  await wait(250);
  mark('flash_end');
  _flash.value = false;
  await wait(300);
}

Future<void> _wait4Login() async {
  while (Get.find<AuthController>().status.value != AuthStatus.unauthenticated) {
    await wait(50);
  }
  await wait(2000);
}

Future<void> _login(String p) async {
  await _wait4Login();
  mark('${p}_login_landed');
  final c = Get.find<PhoneEntryController>();
  await keyboard(true);
  mark('${p}_login_keyboard');
  await type(c.phoneController, '300');
  mark('${p}_login_typed_short');
  await c.requestOtp(); // too short: the existing message, the content shakes
  await wait(130);
  mark('${p}_login_error_shaking');
  await wait(900);
  mark('${p}_login_error_shown');
  c.phoneController.clear();
  await type(c.phoneController, '03001234567', perChar: 60);
  mark('${p}_login_filled');
  await keyboard(false);
  unawaited(c.requestOtp());
  await wait(200);
  mark('${p}_login_morphing');
  await wait(600);
  mark('${p}_login_spinner');
  await wait(900);
  mark('${p}_otp_screen');
  await wait(1500);
  mark('${p}_otp_settled');
  await keyboard(true);
  mark('${p}_otp_keyboard');
  await keyboard(false);
  Get.back();
  await wait(1200);
  mark('${p}_back_on_login');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  runApp(GetMaterialApp(
    title: 'Eldermin Parent',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    initialBinding: _Binding(),
    getPages: AppPages.pages,
    builder: (context, child) => ListenableBuilder(
      listenable: Listenable.merge([_kb, _flash]),
      builder: (context, _) {
        final mq = MediaQuery.of(context);
        final kb = _kb.value;
        return Stack(textDirection: TextDirection.ltr, children: [
          Positioned.fill(
            child: MediaQuery(
              data: mq.copyWith(
                disableAnimations: _reduce || mq.disableAnimations,
                textScaler: _scale == 1 ? mq.textScaler : TextScaler.linear(_scale),
                viewInsets: kb > 0 ? mq.viewInsets.copyWith(bottom: kb) : mq.viewInsets,
                padding: kb > 0 ? mq.padding.copyWith(bottom: 0) : mq.padding,
              ),
              child: child!,
            ),
          ),
          if (kb > 0)
            Positioned(left: 0, right: 0, bottom: 0, height: kb, child: const ColoredBox(color: Color(0xFFD1D5DB))),
          if (_flash.value) const Positioned.fill(child: ColoredBox(color: Color(0xFFFF00FF))),
        ]);
      },
    ),
    home: const _Gate(),
  ));
  unawaited(script());
}
