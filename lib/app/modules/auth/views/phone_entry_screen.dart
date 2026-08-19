import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../components/common_image_view.dart';
import '../../../components/custom_text.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text_field.dart';
import '../../../config/app_images.dart';
import '../controllers/phone_entry_controller.dart';

class PhoneEntryScreen extends StatelessWidget {
  const PhoneEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PhoneEntryController());
    final heroHeight = MediaQuery.of(context).size.height * 0.32;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: _AnimatedGradientBackground(
        child: Stack(
          children: [
            Positioned(right: -60, top: -50, child: _decorRing(190)),
            Positioned(left: -80, top: 120, child: _decorRing(150)),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  SizedBox(
                    height: heroHeight.clamp(190, 260),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 750),
                        curve: Curves.easeOutBack,
                        builder: (context, t, child) => Opacity(
                          opacity: t.clamp(0, 1),
                          child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.22)),
                              ),
                              child: const CommonImageView(
                                imagePath: AppImages.fullLogo,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const CustomText(
                              text: 'Eldermin',
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                            const SizedBox(height: 3),
                            CustomText(
                              text: 'Parent App',
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Transform.translate(
                        offset: Offset(0, (1 - t) * 40),
                        child: Opacity(opacity: t.clamp(0, 1), child: child),
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(color: Color(0x1F0A3158), blurRadius: 30, offset: Offset(0, -10)),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 44,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.line,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const CustomText(
                                text: 'Log in with WhatsApp',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const CustomText(
                                text:
                                    "Enter the WhatsApp number registered with your child's school. We'll send a verification code — no password needed.",
                                color: AppColors.muted,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Obx(() => CustomTextField(
                                    controller: controller.phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s]'))
                                    ],
                                    isborder: true,
                                    fillColor: AppColors.background,
                                    hintText: '+92 300 1234567',
                                    prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primaryColor),
                                    errorText: controller.error.value,
                                  )),
                              const SizedBox(height: AppSpacing.lg),
                              Obx(() => CustomButton(
                                    label: controller.loading.value ? '' : 'Send Verification Code',
                                    height: 54,
                                    color: AppColors.primaryColor,
                                    borderRadius: 16,
                                    enabled: !controller.loading.value,
                                    onPressed: controller.requestOtp,
                                    prefix: controller.loading.value
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : null,
                                  )),
                              const SizedBox(height: AppSpacing.lg),
                              const CustomText(
                                text:
                                    "Haven't registered this number with your school yet? Contact the school office to link it to your child's profile.",
                                textAlign: TextAlign.center,
                                color: AppColors.faint,
                                fontSize: 12,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorRing(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.06), width: size * 0.22),
      ),
    );
  }
}

/// A slow, continuously shifting version of the app's `heroGradient` -
/// the same navy/blue palette used by [HeroCard] and the splash screen,
/// just animated so the very first screen a user sees already feels alive.
class _AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  const _AnimatedGradientBackground({required this.child});

  @override
  State<_AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, -1 + 0.6 * t),
              end: Alignment(1 - 2 * t, 1 - 0.6 * t),
              colors: const [AppColors.primaryColor, Color(0xFF155D96), Color(0xFF237FBD), AppColors.sky],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
