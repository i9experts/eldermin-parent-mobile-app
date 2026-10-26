import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../components/custom_text.dart';
import '../../../routes/app_routes.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'How do I switch between my children?',
      'Tap your child\'s name at the top of the Home or All services screen '
          'to open the student selector, then pick the child whose record '
          'you want to view.',
    ),
    (
      'Where can I see fees and dues?',
      'Open More → Fees & dues for a breakdown of invoices, what\'s been '
          'paid and what\'s outstanding.',
    ),
    (
      'Can I pay fees from the app?',
      'No — this app only shows your fee record. Payments are made '
          'directly through your school\'s office or its own payment '
          'channel.',
    ),
    (
      'How do I request a leave for my child?',
      'Go to More → My leaves and submit the dates and reason. You can '
          'track its status from the same screen.',
    ),
    (
      'How do I respond to a consent request?',
      'Open More → Consent to see any pending requests from the school '
          'and record your decision.',
    ),
    (
      'How do I message a teacher or the school?',
      'Use the Messages tab to start or continue a conversation with '
          'school staff.',
    ),
    (
      'Where can I see attendance, homework and timetable?',
      'These have their own quick-access tiles on the Home screen, and '
          'are also listed under More → All services.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Help & support'),
      body: ListView(
        padding: EmSpacing.listPadding,
        children: [
          const SectionRow(title: 'Frequently asked questions'),
          ..._faqs.map((f) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(text: f.$1, color: AppColors.primaryColor, fontSize: 12, fontWeight: FontWeight.w800, height: 1.35),
                    const SizedBox(height: 6),
                    CustomText(text: f.$2, color: AppColors.muted, fontSize: 11, height: 1.5),
                  ],
                ),
              )),
          const SizedBox(height: EmSpacing.s8),
          const SectionRow(title: 'Still need help?'),
          ListCardRow(
            icon: Icons.forum_outlined,
            iconColor: AppColors.blue,
            title: 'Message your school',
            subtitle: 'Reach staff directly from the Messages tab.',
          ),
          const SizedBox(height: EmSpacing.s8),
          ListCardRow(
            icon: Icons.feedback_outlined,
            iconColor: AppColors.secondryColor,
            title: 'Send feedback',
            subtitle: 'Report a problem or suggest an improvement.',
            onTap: () => Get.toNamed(Routes.feedback),
          ),
          const SizedBox(height: EmSpacing.s12),
        ],
      ),
    );
  }
}
