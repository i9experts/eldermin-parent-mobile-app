import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../routes/app_routes.dart';
import '../controllers/email_sign_in_controller.dart';
import '../widgets/auth_page_shell.dart';

/// Email + password sign in (self-serve accounts): photo header, form on the navy.
class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  late final EmailSignInController controller = Get.put(EmailSignInController());
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
    return AuthPageShell(
      showBack: true,
      shake: _shake,
      eyebrow: 'Sign In',
      title: 'Welcome back',
      subtitle: 'Sign in with the email and password you created your account with.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            hintText: 'Email address',
            prefixIcon: Icons.mail_outline,
          ),
          const SizedBox(height: EmSpacing.s12),
          Obx(() => AuthTextField(
                controller: controller.passwordController,
                obscureText: controller.obscurePassword.value,
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                suffix: AuthPasswordToggle(obscured: controller.obscurePassword.value, onToggle: controller.togglePasswordVisibility),
              )),
          Obx(() => controller.error.value != null
              ? Padding(padding: const EdgeInsets.only(top: EmSpacing.s8), child: AuthMessage(controller.error.value!))
              : const SizedBox.shrink()),
          const SizedBox(height: EmSpacing.s20),
          Obx(() => EmMorphButton(
                label: 'Sign In',
                loadingLabel: 'Signing in',
                phase: controller.loading.value ? EmMorphPhase.loading : EmMorphPhase.idle,
                onPressed: controller.signIn,
              )),
          const SizedBox(height: EmSpacing.s12),
          Center(
            child: TextButton(
              onPressed: () => Get.offNamed(Routes.createAccount),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: "Don't have an account? ", style: EmType.body.copyWith(color: EmColors.primaryContainer, fontWeight: FontWeight.w400)),
                TextSpan(text: 'Create Account', style: EmType.body.copyWith(color: EmColors.accent, fontWeight: FontWeight.w700)),
              ])),
            ),
          ),
        ],
      ),
    );
  }
}
