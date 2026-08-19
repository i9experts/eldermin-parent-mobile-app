import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';

class PhoneEntryController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();

  final phoneController = TextEditingController(text: '+92 ');
  final loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  Future<void> requestOtp() async {
    final phone = phoneController.text.trim();
    if (phone.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
      error.value = 'Enter your complete WhatsApp number.';
      return;
    }
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
    } finally {
      loading.value = false;
    }
  }
}
