import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
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

    return EmScaffold(
      appBar: EmAppBar(title: 'Send feedback'),
      body: ListView(
        padding: EmSpacing.listPadding,
        children: [
          const ScreenIntro(caption: "Tell the school what's on your mind"),
          const SizedBox(height: EmSpacing.s16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: titleCtrl,
                  label: 'Subject',
                  hintText: 'A short summary',
                  isborder: true,
                  fillColor: EmColors.background,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: descriptionCtrl,
                  label: 'Description',
                  hintText: 'Share the details',
                  maxLines: 5,
                  isborder: true,
                  fillColor: EmColors.background,
                ),
                const SizedBox(height: 14),
                const CustomText(
                  text: 'Priority',
                  color: EmColors.textSecondary,
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
                    padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
                    child: CustomText(
                      text: error,
                      color: EmColors.error,
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
                      color: EmColors.primaryDark,
                      enabled: !controller.submitting.value,
                      prefix: controller.submitting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: EmColors.onPrimary))
                          : null,
                      onPressed: () async {
                        final ok = await controller.submit(
                          title: titleCtrl.text,
                          description: descriptionCtrl.text,
                        );
                        if (ok) {
                          // Navigator.pop, not Get.back(): Get.back() only closes an open GetX snackbar (e.g. one left by an earlier failed
                          // attempt, or the one shown here) and leaves the screen up.
                          if (context.mounted) Navigator.of(context).pop();
                          CustomAppSnackbar.success('Thanks — your feedback has been submitted.');
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
