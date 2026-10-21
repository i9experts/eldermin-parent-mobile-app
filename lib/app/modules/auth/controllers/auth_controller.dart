import 'package:get/get.dart';
import '../../../../core/services/app_preferences.dart';
import '../../../../core/services/device_activation_service.dart';
import '../../students/controllers/student_controller.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Global session state - the single source of truth for whether the app
/// shows the login flow or the home shell. Registered once (permanent) in
/// InitialBinding so it survives for the whole app lifetime.
class AuthController extends GetxController {
  final status = AuthStatus.unknown.obs;
  final userName = RxnString();
  final userPhone = RxnString();
  // A self-serve ParentLead account (see loginSuccess) - its token isn't
  // recognized by the real-guardian endpoints (my-students, device-ping),
  // so those calls must be skipped entirely rather than 401 and trigger
  // the global "session died" logout right after a fresh signup.
  final isParentLead = false.obs;
  final schoolOnboarded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Runs alongside the real token/profile read below so the splash
    // screen's entrance animation always gets to finish, even on a
    // fast device where bootstrap alone would resolve in a few ms.
    final minSplashDuration = Future.delayed(const Duration(seconds: 3));

    final token = await AppPreferences.getAccessTokenAsync();
    if (token == null) {
      await minSplashDuration;
      status.value = AuthStatus.unauthenticated;
      return;
    }
    userName.value = await AppPreferences.getUserName();
    userPhone.value = await AppPreferences.getUserPhone();
    isParentLead.value = await AppPreferences.getIsParentLead();
    schoolOnboarded.value = await AppPreferences.getSchoolOnboarded();
    await minSplashDuration;
    status.value = AuthStatus.authenticated;
    if (!isParentLead.value) {
      Get.find<StudentController>().fetchMyStudents();
      // Returning user, cold start - counts as "the app was actually
      // opened", not just "the app was once logged into".
      Get.find<DeviceActivationService>().pingNow();
    }
  }

  /// [isParentLead] / [schoolOnboarded] are only meaningful for the
  /// self-serve email+password signup (see CreateAccountController /
  /// EmailSignInController) - a real guardian logging in via phone+OTP
  /// always passes isParentLead: false, since fetchMyStudents/pingNow are
  /// exactly the calls that account type's endpoints answer correctly.
  Future<void> loginSuccess({
    required String token,
    required String name,
    required String phone,
    bool isParentLead = false,
    bool schoolOnboarded = false,
  }) async {
    await AppPreferences.setAccessToken(token);
    await AppPreferences.saveUserInfo(name: name, phone: phone);
    await AppPreferences.saveLeadStatus(isParentLead: isParentLead, schoolOnboarded: schoolOnboarded);
    userName.value = name;
    userPhone.value = phone;
    this.isParentLead.value = isParentLead;
    this.schoolOnboarded.value = schoolOnboarded;
    status.value = AuthStatus.authenticated;
    if (!isParentLead) {
      Get.find<StudentController>().fetchMyStudents();
      Get.find<DeviceActivationService>().pingNow();
    }
  }

  /// Full logout AND "Switch User" both call this - there's no partial
  /// sign-out state, since leaving a stale token or student selection
  /// around risks mixing one guardian's session with another's.
  Future<void> logout() async {
    await AppPreferences.clearPreference();
    userName.value = null;
    userPhone.value = null;
    isParentLead.value = false;
    schoolOnboarded.value = false;
    Get.find<StudentController>().reset();
    status.value = AuthStatus.unauthenticated;
  }
}
