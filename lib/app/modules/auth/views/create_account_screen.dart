import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../components/custom_text.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text_field.dart';
import '../../../routes/app_routes.dart';
import '../controllers/create_account_controller.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateAccountController());

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
        title: const CustomText(
          text: 'Create Account',
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
                text: "No school linked yet? No problem.",
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: AppSpacing.xs),
              const CustomText(
                text:
                    "Create an account now - as soon as your child's school joins SmartVan, you'll be ready to start tracking the van.",
                color: AppColors.grey,
              ),
              const SizedBox(height: AppSpacing.lg),

              _label('Full Name'),
              CustomTextField(
                controller: controller.fullNameController,
                isborder: true,
                fillColor: AppColors.background,
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryColor),
              ),
              const SizedBox(height: AppSpacing.md),

              _label("School Name"),
              CustomTextField(
                controller: controller.schoolNameController,
                isborder: true,
                fillColor: AppColors.background,
                hintText: "Your child's school name",
                prefixIcon: const Icon(Icons.school_outlined, color: AppColors.primaryColor),
              ),
              const SizedBox(height: AppSpacing.md),

              _label('Email Address'),
              CustomTextField(
                controller: controller.emailController,
                isborder: true,
                fillColor: AppColors.background,
                keyboardType: TextInputType.emailAddress,
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.mail_outline, color: AppColors.primaryColor),
              ),
              const SizedBox(height: AppSpacing.md),

              _label('Phone Number'),
              CustomTextField(
                controller: controller.phoneController,
                isborder: true,
                fillColor: AppColors.background,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s]'))],
                hintText: '+92 300 1234567',
                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primaryColor),
              ),
              const SizedBox(height: AppSpacing.md),

              _label('Password'),
              Obx(() => CustomTextField(
                    controller: controller.passwordController,
                    isborder: true,
                    fillColor: AppColors.background,
                    obscureText: controller.obscurePassword.value,
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.grey),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  )),
              const SizedBox(height: AppSpacing.md),

              _label('Confirm Password'),
              Obx(() => CustomTextField(
                    controller: controller.confirmPasswordController,
                    isborder: true,
                    fillColor: AppColors.background,
                    obscureText: controller.obscureConfirmPassword.value,
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(controller.obscureConfirmPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.grey),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                  )),
              const SizedBox(height: AppSpacing.md),

              Obx(() => InkWell(
                    onTap: controller.toggleAgreedToTerms,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: controller.agreedToTerms.value,
                          activeColor: AppColors.primaryColor,
                          onChanged: (_) => controller.toggleAgreedToTerms(),
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 14),
                            child: CustomText(
                              text: 'I agree to the Terms & Conditions and Privacy Policy',
                              color: AppColors.grey,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

              Obx(() => controller.error.value != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: CustomText(text: controller.error.value!, color: Colors.red, fontSize: 12.5),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: AppSpacing.lg),
              Obx(() => CustomButton(
                    label: controller.loading.value ? '' : 'Create Account',
                    height: 54,
                    color: AppColors.accentColor,
                    textColor: AppColors.primaryColor,
                    fontWeight: FontWeight.w800,
                    borderRadius: 16,
                    enabled: !controller.loading.value,
                    onPressed: controller.createAccount,
                    prefix: controller.loading.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor))
                        : null,
                  )),
              const SizedBox(height: AppSpacing.md),

              Center(
                child: TextButton(
                  onPressed: () => Get.offNamed(Routes.emailSignIn),
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Already have an account? ', style: TextStyle(color: AppColors.grey)),
                      TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.w700)),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: CustomText(text: text, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryColor),
      );
}
