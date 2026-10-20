import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import 'auth_controller.dart';

class EmailSignInController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final AuthController _auth = Get.find<AuthController>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;
  final loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() => obscurePassword.value = !obscurePassword.value;

  Future<void> signIn() async {
    final email = emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      error.value = 'Enter a valid email address.';
      return;
    }
    if (passwordController.text.isEmpty) {
      error.value = 'Enter your password.';
      return;
    }
    loading.value = true;
    error.value = null;

    try {
      final result = await _api.loginLead(email, passwordController.text);
      final user = result['user'] as Map<String, dynamic>;
      await _auth.loginSuccess(
        token: result['accessToken'] as String,
        name: user['fullName'] as String? ?? 'Parent',
        phone: user['phone'] as String? ?? '',
        isParentLead: true,
        schoolOnboarded: user['isSchoolOnboarded'] as bool? ?? false,
      );
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }
}
