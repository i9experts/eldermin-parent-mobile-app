import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import 'auth_controller.dart';

class CreateAccountController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final AuthController _auth = Get.find<AuthController>();

  final fullNameController = TextEditingController();
  final schoolNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController(text: '+92 ');
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final agreedToTerms = false.obs;
  final loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onClose() {
    fullNameController.dispose();
    schoolNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() => obscurePassword.value = !obscurePassword.value;
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.value = !obscureConfirmPassword.value;
  void toggleAgreedToTerms() => agreedToTerms.value = !agreedToTerms.value;

  String? _validate() {
    if (fullNameController.text.trim().isEmpty) return 'Enter your full name.';
    if (schoolNameController.text.trim().isEmpty) return "Enter your child's school name.";
    final email = emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Enter a valid email address.';
    if (phoneController.text.replaceAll(RegExp(r'[^\d]'), '').length < 10) return 'Enter your complete phone number.';
    if (passwordController.text.length < 8) return 'Password must be at least 8 characters.';
    if (passwordController.text != confirmPasswordController.text) return 'Passwords do not match.';
    if (!agreedToTerms.value) return 'Please accept the Terms & Conditions and Privacy Policy.';
    return null;
  }

  /// Best-effort, one-time location capture for the Super Admin growth
  /// dashboard's city/country filters - never blocks or fails account
  /// creation. A denied permission, a disabled location service, or a
  /// timeout all just mean the account is created with no location tag.
  Future<Map<String, double>?> _captureLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 8)),
      );
      return {'lat': position.latitude, 'lng': position.longitude};
    } catch (_) {
      return null;
    }
  }

  Future<void> createAccount() async {
    final validationError = _validate();
    if (validationError != null) {
      error.value = validationError;
      return;
    }
    loading.value = true;
    error.value = null;

    try {
      final location = await _captureLocation();
      final result = await _api.registerLead({
        'fullName': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'password': passwordController.text,
        'schoolName': schoolNameController.text.trim(),
        if (location != null) 'lat': location['lat'],
        if (location != null) 'lng': location['lng'],
      });
      final user = result['user'] as Map<String, dynamic>;
      await _auth.loginSuccess(
        token: result['accessToken'] as String,
        name: user['fullName'] as String? ?? 'Parent',
        phone: user['phone'] as String? ?? phoneController.text.trim(),
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
