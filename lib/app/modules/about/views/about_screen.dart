import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../components/custom_text.dart';
import '../../../config/app_images.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _capabilities = [
    ('Attendance', 'Daily attendance for every linked child, term to date.'),
    ('Homework & learning resources', 'Assignments, due dates and shared study material.'),
    ('Timetable & datesheet', 'Class schedules and upcoming exam dates.'),
    ('Fees & dues', 'A clear view of invoices, payments and balances (view-only).'),
    ('Medical', 'Health information your school has on file for your child.'),
    ('Behaviour & Tarbiyah', 'Conduct notes and character-development tracking.'),
    ('Library', 'Books currently issued and due dates.'),
    ('Consent requests', 'Review and respond to school consent requests.'),
    ('Leaves', 'Request and track leave applications.'),
    ('Parent-teacher meetings', 'Past and scheduled PTM records.'),
    ('Circulars & notifications', 'School-wide announcements and alerts.'),
    ('Messages & feedback', 'Direct messaging with staff and a channel for feedback.'),
  ];

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'About us'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(color: AppColors.primaryColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Image.asset(AppImages.fullLogo, fit: BoxFit.contain),
                ),
                const SizedBox(height: AppSpacing.sm),
                const CustomText(
                  text: 'Eldermin',
                  color: AppColors.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                const SizedBox(height: 2),
                const CustomText(
                  text: 'Parent app · Version 1.0.4',
                  color: AppColors.muted,
                  fontSize: 11.5,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CustomText(
                  text: 'Stay connected, stay informed.',
                  color: AppColors.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                SizedBox(height: 8),
                CustomText(
                  text: 'Eldermin is your school\'s student information system. This '
                      'parent app is a direct window into it, so what you see here is '
                      'always the same record your school\'s office is working from — '
                      'attendance, academics, fees, health and conduct for every child '
                      'you have linked to your account.',
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionRow(title: 'What you can do here'),
          ..._capabilities.map((c) => AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(text: c.$1, color: AppColors.primaryColor, fontSize: 12, fontWeight: FontWeight.w800),
                          const SizedBox(height: 3),
                          CustomText(text: c.$2, color: AppColors.muted, fontSize: 10.5, height: 1.4),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: CustomText(
              text: '© ${DateTime.now().year} Eldermin. Built for families who want '
                  'a clear, honest view of school life.',
              color: AppColors.faint,
              fontSize: 10,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
