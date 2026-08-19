import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text.dart';
import '../../../components/custom_text_field.dart';
import '../controllers/feedback_controller.dart';

class FeedbackScreen extends GetView<FeedbackController> {
  const FeedbackScreen({super.key});

  static const _priorities = ['low', 'medium', 'high', 'urgent'];

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
        text: 'Send feedback',
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      )),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const ScreenHeader(title: 'Send feedback', caption: "Tell the school what's on your mind"),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: titleCtrl,
                  label: 'Subject',
                  hintText: 'A short summary',
                  isborder: true,
                  fillColor: AppColors.background,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: descriptionCtrl,
                  label: 'Description',
                  hintText: 'Share the details',
                  maxLines: 5,
                  isborder: true,
                  fillColor: AppColors.background,
                ),
                const SizedBox(height: 14),
                const CustomText(
                  text: 'Priority',
                  color: AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 8),
                Obx(() => SegmentedControl(
                      options: _priorities.map((p) => p[0].toUpperCase() + p.substring(1)).toList(),
                      selectedIndex: _priorities.indexOf(controller.priority.value),
                      onChanged: (i) => controller.priority.value = _priorities[i],
                    )),
                const SizedBox(height: 16),
                Obx(() {
                  final error = controller.error.value;
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomText(
                      text: error,
                      color: AppColors.red,
                      fontSize: 11,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                Obx(() => CustomButton(
                      label: controller.submitting.value ? '' : 'Submit feedback',
                      width: double.infinity,
                      height: 48,
                      color: AppColors.primaryColor,
                      enabled: !controller.submitting.value,
                      prefix: controller.submitting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : null,
                      onPressed: () async {
                        final ok = await controller.submit(
                          title: titleCtrl.text,
                          description: descriptionCtrl.text,
                        );
                        if (ok) {
                          CustomAppSnackbar.success('Thanks — your feedback has been submitted.');
                          Get.back();
                        } else if (controller.error.value != null) {
                          CustomAppSnackbar.error(controller.error.value!);
                        }
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
