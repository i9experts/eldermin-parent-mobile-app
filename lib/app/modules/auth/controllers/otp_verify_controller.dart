import 'dart:async';
import 'package:get/get.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../components/custom_app_snack_bar.dart';
import 'auth_controller.dart';

class OtpVerifyController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final AuthController _auth = Get.find<AuthController>();

  late final String phone;
  late final String? devCode;

  final code = ''.obs;
  final loading = false.obs;
  final RxnString error = RxnString();
  final resendSeconds = 45.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    phone = args['phone'] as String? ?? '';
    devCode = args['devCode'] as String?;
    _startResendTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startResendTimer() {
    resendSeconds.value = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSeconds.value <= 1) {
        t.cancel();
        resendSeconds.value = 0;
      } else {
        resendSeconds.value--;
      }
    });
  }

  void onCodeChanged(String value) => code.value = value;

  Future<void> verify() async {
    if (code.value.length != 6) return;
    loading.value = true;
    error.value = null;

    try {
      final result = await _api.verifyOtp(phone, code.value);
      final user = result['user'] as Map<String, dynamic>;
      await _auth.loginSuccess(
        token: result['accessToken'] as String,
        name: user['name'] as String? ?? 'Parent',
        phone: user['phone'] as String? ?? phone,
      );
      // AuthController flips `status`, and AuthGate clears the navigation
      // stack whenever that happens - no manual pop needed here.
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  Future<void> resend() async {
    try {
      await _api.requestOtp(phone);
      _startResendTimer();
      CustomAppSnackbar.success('A new code was sent to your WhatsApp.');
    } on ApiException catch (e) {
      CustomAppSnackbar.error(e.message);
    }
  }
}
