import 'package:get/get.dart';
import '../../../../core/services/app_preferences.dart';
import '../../students/controllers/student_controller.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Global session state - the single source of truth for whether the app
/// shows the login flow or the home shell. Registered once (permanent) in
/// InitialBinding so it survives for the whole app lifetime.
class AuthController extends GetxController {
  final status = AuthStatus.unknown.obs;
  final userName = RxnString();
  final userPhone = RxnString();

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Runs alongside the real token/profile read below so the splash
    // screen's entrance animation always gets to finish, even on a
    // fast device where bootstrap alone would resolve in a few ms.
    final minSplashDuration = Future.delayed(const Duration(milliseconds: 1400));

    final token = await AppPreferences.getAccessTokenAsync();
    if (token == null) {
      await minSplashDuration;
      status.value = AuthStatus.unauthenticated;
      return;
    }
    userName.value = await AppPreferences.getUserName();
    userPhone.value = await AppPreferences.getUserPhone();
    await minSplashDuration;
    status.value = AuthStatus.authenticated;
    Get.find<StudentController>().fetchMyStudents();
  }

  Future<void> loginSuccess(
      {required String token,
      required String name,
      required String phone}) async {
    await AppPreferences.setAccessToken(token);
    await AppPreferences.saveUserInfo(name: name, phone: phone);
    userName.value = name;
    userPhone.value = phone;
    status.value = AuthStatus.authenticated;
    Get.find<StudentController>().fetchMyStudents();
  }

  /// Full logout AND "Switch User" both call this - there's no partial
  /// sign-out state, since leaving a stale token or student selection
  /// around risks mixing one guardian's session with another's.
  Future<void> logout() async {
    await AppPreferences.clearPreference();
    userName.value = null;
    userPhone.value = null;
    Get.find<StudentController>().reset();
    status.value = AuthStatus.unauthenticated;
  }
}
