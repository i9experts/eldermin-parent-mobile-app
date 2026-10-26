import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../routes/app_routes.dart';
import '../controllers/create_account_controller.dart';
import '../widgets/auth_page_shell.dart';

/// Create a self-serve account: photo header, form on the navy.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  late final CreateAccountController controller = Get.put(CreateAccountController());
  final _shake = ValueNotifier<int>(0);
  Worker? _errors;

  @override
  void initState() {
    super.initState();
    _errors = ever(controller.error, (e) {
      if (e != null) _shake.value++;
    });
  }

  @override
  void dispose() {
    _errors?.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: EmSpacing.s16);
    return AuthPageShell(
      showBack: true,
      shake: _shake,
      eyebrow: 'Create Account',
      title: 'No school linked yet? No problem.',
      subtitle:
          "Create an account now - as soon as your child's school joins SmartVan, you'll be ready to start tracking the van.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmTextField(
            label: 'Full Name',controller: controller.fullNameController, hint: 'Enter your full name', prefixIcon: Icons.person_outline),
          gap,
          EmTextField(
            label: 'School Name',controller: controller.schoolNameController, hint: "Your child's school name", prefixIcon: Icons.school_outlined),
          gap,
          EmTextField(
            label: 'Email Address',
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            hint: 'Enter your email',
            prefixIcon: Icons.mail_outline,
            fillColor: EmColors.background,
            radius: EmRadius.control,
          ),
          gap,
          EmTextField(
            label: 'Phone Number',
            controller: controller.phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s]'))],
            hint: '+92 300 1234567',
            prefixIcon: Icons.phone_iphone_rounded,
            fillColor: EmColors.background,
            radius: EmRadius.control,
          ),
          gap,
          Obx(() => EmTextField(
            label: 'Password',
                controller: controller.passwordController,
                obscureText: controller.obscurePassword.value,
                hint: 'Create a password',
                prefixIcon: Icons.lock_outline,
                fillColor: EmColors.background,
                radius: EmRadius.control,
                suffix: PasswordVisibilityButton(obscured: controller.obscurePassword.value, onToggle: controller.togglePasswordVisibility),
              )),
          gap,
          Obx(() => EmTextField(
            label: 'Confirm Password',
                controller: controller.confirmPasswordController,
                obscureText: controller.obscureConfirmPassword.value,
                hint: 'Confirm your password',
                prefixIcon: Icons.lock_outline,
                fillColor: EmColors.background,
                radius: EmRadius.control,
                suffix: PasswordVisibilityButton(
                    obscured: controller.obscureConfirmPassword.value, onToggle: controller.toggleConfirmPasswordVisibility),
              )),
          gap,
          Obx(() => InkWell(
                onTap: controller.toggleAgreedToTerms,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: controller.agreedToTerms.value,
                      activeColor: EmColors.accent,
                      checkColor: EmColors.ink,
                      side: const BorderSide(color: EmColors.primaryLight, width: 1.5),
                      onChanged: (_) => controller.toggleAgreedToTerms(),
                    ),
                    Expanded(
                      child: Text('I agree to the Terms & Conditions and Privacy Policy',
                          style: EmType.caption.copyWith(color: EmColors.primaryContainer, fontWeight: FontWeight.w400)),
                    ),
                  ],
                ),
              )),
          Obx(() => controller.error.value != null
              ? Padding(padding: const EdgeInsets.only(top: EmSpacing.s12), child: AuthBanner(message: controller.error.value!))
              : const SizedBox.shrink()),
          const SizedBox(height: EmSpacing.s20),
          Obx(() => EmMorphButton(
                label: 'Create Account',
                loadingLabel: 'Creating your account',
                phase: controller.loading.value ? EmMorphPhase.loading : EmMorphPhase.idle,
                onPressed: controller.createAccount,
              )),
          const SizedBox(height: EmSpacing.s12),
          Center(
            child: TextButton(
              onPressed: () => Get.offNamed(Routes.emailSignIn),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: 'Already have an account? ', style: EmType.body.copyWith(color: EmColors.primaryContainer, fontWeight: FontWeight.w400)),
                TextSpan(text: 'Sign In', style: EmType.body.copyWith(color: EmColors.onPrimaryDark, fontWeight: FontWeight.w700)),
              ])),
            ),
          ),
        ],
      ),
    );
  }
}
