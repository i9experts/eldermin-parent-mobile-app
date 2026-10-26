import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/otp_verify_controller.dart';
import '../widgets/auth_page_shell.dart';

/// Verification code (pushed from the login screen): photo header, code boxes on the navy.
class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  late final OtpVerifyController controller = Get.find<OtpVerifyController>();
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
      eyebrow: 'Verify Number',
      title: 'Enter the code',
      subtitle: 'We sent a 6-digit code via WhatsApp to ${controller.phone}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.devCode != null) ...[
            Container(
              padding: const EdgeInsets.all(EmSpacing.s12),
              decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(EmRadius.md)),
              child: Row(children: [
                const Icon(Icons.science_outlined, color: AppColors.amberText, size: 20),
                const SizedBox(width: EmSpacing.s8),
                Expanded(
                    child: Text('Dev mode code: ${controller.devCode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: EmType.body.copyWith(color: AppColors.amberText, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: EmSpacing.s20),
          ],
          PinCodeTextField(
            appContext: context,
            length: 6,
            onChanged: controller.onCodeChanged,
            onCompleted: (_) => controller.verify(),
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            cursorColor: EmColors.accent,
            textStyle: EmType.heading.copyWith(color: EmColors.onPrimaryDark),
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(EmRadius.control),
              fieldHeight: 52,
              fieldWidth: 44,
              borderWidth: 1,
              activeColor: EmColors.primaryLight,
              selectedColor: EmColors.accent,
              inactiveColor: EmColors.primaryLight,
              activeFillColor: Colors.transparent,
              inactiveFillColor: Colors.transparent,
              selectedFillColor: Colors.transparent,
            ),
          ),
          Obx(() => controller.error.value != null
              ? Padding(padding: const EdgeInsets.only(top: EmSpacing.s12), child: AuthBanner(message: controller.error.value!))
              : const SizedBox.shrink()),
          const SizedBox(height: EmSpacing.s20),
          Obx(() => EmMorphButton(
                label: 'Verify & Continue',
                loadingLabel: 'Verifying',
                phase: controller.loading.value ? EmMorphPhase.loading : EmMorphPhase.idle,
                onPressed: controller.code.value.length == 6 ? controller.verify : null,
              )),
          const SizedBox(height: EmSpacing.s16),
          Center(
            child: Obx(() => controller.resendSeconds.value > 0
                ? Text('Resend code in ${controller.resendSeconds.value} s',
                    style: EmType.body.copyWith(color: EmColors.primaryContainer, fontWeight: FontWeight.w400))
                : TextButton(
                    onPressed: controller.resend,
                    child: Text('Resend Code', style: EmType.body.copyWith(color: EmColors.onPrimaryDark, fontWeight: FontWeight.w700)))),
          ),
        ],
      ),
    );
  }
}
