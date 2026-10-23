import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../routes/app_routes.dart';
import '../controllers/phone_entry_controller.dart';
import '../widgets/auth_page_shell.dart';

/// The login (root) screen: WhatsApp number -> verification code. Photo header, form on the navy.
class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  late final PhoneEntryController controller = Get.put(PhoneEntryController());
  final _shake = ValueNotifier<int>(0);
  Worker? _errors;

  @override
  void initState() {
    super.initState();
    // the existing error message is already shown; the content shakes gently as it appears
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
      photoSize: AuthPhotoSize.tall,
      shake: _shake,
      title: 'Log in with WhatsApp',
      subtitle:
          "Enter the WhatsApp number registered with your child's school. We'll send a verification code — no password needed.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => AuthTextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s]'))],
                hintText: '3001234567',
                prefixIcon: Icons.phone_iphone_rounded,
                errorText: controller.error.value,
              )),
          const SizedBox(height: EmSpacing.s20),
          Obx(() => EmMorphButton(
                label: 'Send Verification Code',
                loadingLabel: 'Sending the code',
                phase: controller.loading.value ? EmMorphPhase.loading : EmMorphPhase.idle,
                onPressed: controller.requestOtp,
              )),
          const SizedBox(height: EmSpacing.s20),
          Text(
            "Haven't registered this number with your school yet? Contact the school office to link it to your child's profile.",
            textAlign: TextAlign.center,
            style: EmType.caption.copyWith(color: EmColors.primaryContainer, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: EmSpacing.s8),
          Center(
            child: TextButton(
              onPressed: () => Get.toNamed(Routes.createAccount),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: "Your school isn't on Eldermin yet? ",
                      style: EmType.caption.copyWith(color: EmColors.primaryContainer, fontWeight: FontWeight.w400)),
                  TextSpan(text: 'Create an account', style: EmType.caption.copyWith(color: EmColors.accent, fontWeight: FontWeight.w700)),
                ]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
