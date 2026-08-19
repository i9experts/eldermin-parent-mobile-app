import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text.dart';
import '../controllers/otp_verify_controller.dart';

class OtpVerifyScreen extends GetView<OtpVerifyController> {
  const OtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Verify Number',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              const CustomText(
                  text: 'Enter the code',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor),
              const SizedBox(height: AppSpacing.xs),
              CustomText(
                  text: 'We sent a 6-digit code via WhatsApp to ${controller.phone}',
                  color: AppColors.muted),
              if (controller.devCode != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                      color: AppColors.amberBg,
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(children: [
                    const Icon(Icons.science_outlined,
                        color: AppColors.amberText, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: CustomText(
                            text: 'Dev mode code: ${controller.devCode}',
                            color: AppColors.amberText,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PinCodeTextField(
                appContext: context,
                length: 6,
                onChanged: controller.onCodeChanged,
                onCompleted: (_) => controller.verify(),
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  fieldHeight: 52,
                  fieldWidth: 44,
                  activeColor: AppColors.primaryColor,
                  selectedColor: AppColors.primaryColor,
                  inactiveColor: AppColors.line,
                  activeFillColor: AppColors.background,
                  inactiveFillColor: AppColors.background,
                  selectedFillColor: AppColors.background,
                ),
              ),
              Obx(() => controller.error.value != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: CustomText(
                          text: controller.error.value!,
                          color: AppColors.red,
                          fontSize: 13),
                    )
                  : const SizedBox.shrink()),
              const SizedBox(height: AppSpacing.lg),
              Obx(() => CustomButton(
                    label: controller.loading.value ? '' : 'Verify & Continue',
                    height: 52,
                    color: AppColors.primaryColor,
                    enabled: !controller.loading.value &&
                        controller.code.value.length == 6,
                    onPressed: controller.verify,
                    prefix: controller.loading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : null,
                  )),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Obx(() => controller.resendSeconds.value > 0
                    ? CustomText(
                        text: 'Resend code in ${controller.resendSeconds.value} s',
                        color: AppColors.faint)
                    : TextButton(
                        onPressed: controller.resend,
                        child: const CustomText(
                            text: 'Resend Code',
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
