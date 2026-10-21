import 'package:eldermin_parent_app/app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';

class PhoneEntryController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();

  final phoneController = TextEditingController();
  final loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  String _localDigits(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('92')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  Future<void> requestOtp() async {
    final localDigits = _localDigits(phoneController.text);
    if (localDigits.length < 10) {
      error.value = 'Enter your complete WhatsApp number.';
      return;
    }
    final phone = '+92$localDigits';
    loading.value = true;
    error.value = null;

    try {
      final result = await _api.requestOtp(phone);

      if (result['sent'] == false && result['devCode'] == null) {
        error.value =
            "Couldn't send the code right now: ${result['reason'] ?? 'please try again shortly.'}";
        return;
      }

      Get.toNamed(Routes.otpVerify,
          arguments: {'phone': phone, 'devCode': result['devCode'] as String?});
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }
}
