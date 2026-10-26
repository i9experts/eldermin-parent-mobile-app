import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../components/custom_text.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      'Information we hold',
      'To run your child\'s school record, Eldermin holds the academic, '
          'attendance, fee, health, behaviour and library data your school '
          'enters into its system, plus the contact details (name and phone '
          'number) you registered with the school for parent access. All of '
          'it originates from your school, not from third parties.',
    ),
    (
      'How we use it',
      'This data is used only to show you your own children\'s records in '
          'this app — attendance, homework, timetable, fees and dues, '
          'medical information on file, behaviour and Tarbiyah notes, '
          'library activity, consent requests, leave requests, PTM history, '
          'circulars and messages from staff.',
    ),
    (
      'Who can see it',
      'Only you, as a verified parent or guardian, and the staff at your '
          'child\'s school who already have access to that record in the '
          'school system. Eldermin does not sell, rent or share your '
          'family\'s data with advertisers or any other third party.',
    ),
    (
      'How you sign in',
      'Access is verified with a one-time code sent to your registered '
          'phone number. We do not store that code after it is used, and we '
          'never ask for it outside the app\'s sign-in screen.',
    ),
    (
      'Payments',
      'This app does not process or store any payment information. Fees '
          'and dues shown here are for your reference; any payment is made '
          'directly through your school\'s office or its designated payment '
          'channel, outside this app.',
    ),
    (
      'Data about minors',
      'Most of the records in this app belong to your children, who are '
          'minors. That data is entered and controlled by your school under '
          'its own enrolment agreement with you, and this app only displays '
          'it to the parent or guardian account it is linked to.',
    ),
    (
      'How long we keep it',
      'Records are retained for as long as your child is enrolled and for '
          'the period afterward that your school\'s policy and applicable '
          'record-keeping requirements call for. Removing the app from your '
          'device does not delete your school\'s records.',
    ),
    (
      'Your choices',
      'You can review what\'s shown about your family at any time inside '
          'the app. To correct, export or delete underlying records, contact '
          'your school directly — they control the source data that this '
          'app displays.',
    ),
    (
      'Changes to this policy',
      'If how we handle data changes in a meaningful way, we\'ll update this '
          'page and, where the change is significant, let you know inside '
          'the app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Privacy policy'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CustomText(
                  text: 'Your family\'s privacy',
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                SizedBox(height: 6),
                CustomText(
                  text: 'This explains what information the Eldermin parent app '
                      'shows and how it is handled. It covers only what this app '
                      'does — your school\'s own privacy policy governs how it '
                      'collects and manages student records more broadly.',
                  color: AppColors.muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._sections.map((s) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(text: s.$1, color: AppColors.primaryColor, fontSize: 12.5, fontWeight: FontWeight.w800),
                    const SizedBox(height: 6),
                    CustomText(text: s.$2, color: AppColors.muted, fontSize: 11, height: 1.55),
                  ],
                ),
              )),
          Center(
            child: CustomText(
              text: 'Questions about this policy? Reach us from More → Feedback.',
              color: AppColors.faint,
              fontSize: 10,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
