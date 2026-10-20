import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../components/custom_text.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text_field.dart';
import '../../../routes/app_routes.dart';
import '../controllers/email_sign_in_controller.dart';

class EmailSignInScreen extends StatelessWidget {
  const EmailSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmailSignInController());

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
        title: const CustomText(
          text: 'Sign In',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomText(
                text: 'Welcome back',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: AppSpacing.xs),
              const CustomText(
                text: 'Sign in with the email and password you created your account with.',
                color: AppColors.grey,
              ),
              const SizedBox(height: AppSpacing.lg),

              CustomTextField(
                controller: controller.emailController,
                isborder: true,
                fillColor: AppColors.background,
                keyboardType: TextInputType.emailAddress,
                hintText: 'Email address',
                prefixIcon: const Icon(Icons.mail_outline, color: AppColors.primaryColor),
              ),
              const SizedBox(height: AppSpacing.md),

              Obx(() => CustomTextField(
                    controller: controller.passwordController,
                    isborder: true,
                    fillColor: AppColors.background,
                    obscureText: controller.obscurePassword.value,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.grey),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  )),

              Obx(() => controller.error.value != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: CustomText(text: controller.error.value!, color: Colors.red, fontSize: 12.5),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: AppSpacing.lg),
              Obx(() => CustomButton(
                    label: controller.loading.value ? '' : 'Sign In',
                    height: 54,
                    color: AppColors.primaryColor,
                    borderRadius: 16,
                    enabled: !controller.loading.value,
                    onPressed: controller.signIn,
                    prefix: controller.loading.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : null,
                  )),
              const SizedBox(height: AppSpacing.md),

              Center(
                child: TextButton(
                  onPressed: () => Get.offNamed(Routes.createAccount),
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: "Don't have an account? ", style: TextStyle(color: AppColors.grey)),
                      TextSpan(text: 'Create Account', style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
