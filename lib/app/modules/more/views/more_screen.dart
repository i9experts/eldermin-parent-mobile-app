import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../components/custom_text.dart';
import '../../../components/svg_icon.dart';
import '../../../config/app_icons.dart';
import '../../shared/views/coming_soon_screen.dart';
import '../../students/controllers/student_controller.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = Get.find<StudentController>();

    final modules = <(Widget, String, VoidCallback)>[
      (
        const Icon(Icons.folder_outlined, color: AppColors.blue),
        'Learning resources',
        () => Get.toNamed(Routes.learningResources)
      ),
      (
        const Icon(Icons.local_library_outlined, color: AppColors.blue),
        'Library',
        () => Get.toNamed(Routes.library)
      ),
      (
        const SvgIcon(assetName: AppIcons.behaviour, size: 22, color: AppColors.blue),
        'Behaviour & Tarbiyah',
        () => Get.toNamed(Routes.tarbiyah)
      ),
      (
        const SvgIcon(assetName: AppIcons.profileIcon, size: 22, color: AppColors.blue),
        'Student profile',
        () => Get.toNamed(Routes.profile)
      ),
      (
        const Icon(Icons.medical_information_outlined, color: AppColors.blue),
        'Medical',
        () => Get.toNamed(Routes.medical)
      ),
      (
        const Icon(Icons.description_outlined, color: AppColors.blue),
        'Academic documents',
        () => Get.toNamed(Routes.documents)
      ),
      (
        const SvgIcon(assetName: AppIcons.checkIcon, size: 22, color: AppColors.blue),
        'Consent',
        () => Get.toNamed(Routes.consent)
      ),
      (
        const Icon(Icons.event_available_outlined, color: AppColors.blue),
        'My leaves',
        () => Get.toNamed(Routes.leaves)
      ),
      (
        const SvgIcon(assetName: AppIcons.calenderIcon, size: 22, color: AppColors.blue),
        'Datesheet',
        () => Get.toNamed(Routes.datesheet)
      ),
      (
        const Icon(Icons.groups_outlined, color: AppColors.blue),
        'Parent-teacher meetings',
        () => Get.toNamed(Routes.ptm)
      ),
      (
        const SvgIcon(assetName: AppIcons.reportIcon, size: 22, color: AppColors.blue),
        'Circulars',
        () => Get.toNamed(Routes.circulars)
      ),
      (
        const SvgIcon(assetName: AppIcons.messageIcon, size: 22, color: AppColors.blue),
        'Inbox',
        () => Get.toNamed(Routes.notifications)
      ),
      (
        const SvgIcon(assetName: AppIcons.messageSendIcon, size: 22, color: AppColors.blue),
        'Feedback',
        () => Get.toNamed(Routes.feedback)
      ),
      (
        const Icon(Icons.switch_account_outlined, color: AppColors.blue),
        'Switch user',
        () => Get.to(() => const ComingSoonScreen(title: 'Switch Account'))
      ),
      (
        const SvgIcon(assetName: AppIcons.privacy, size: 22, color: AppColors.blue),
        'Privacy policy',
        () => Get.to(() => const ComingSoonScreen(title: 'Privacy Policy'))
      ),
      (
        const SvgIcon(assetName: AppIcons.aboutIcon, size: 22, color: AppColors.blue),
        'About us',
        () => Get.to(() => const ComingSoonScreen(title: 'About Eldermin'))
      ),
      (
        const SvgIcon(assetName: AppIcons.faqIcon, size: 22, color: AppColors.blue),
        'Help',
        () => Get.to(() => const ComingSoonScreen(title: 'Help & Support'))
      ),
    ];

    final quickAccessTiles = <(IconData, String, Color, VoidCallback)>[
      (Icons.check_circle_outline_rounded, 'Attendance', AppColors.blue, () => Get.toNamed(Routes.attendance)),
      (Icons.menu_book_rounded, 'Homework', AppColors.amber, () => Get.toNamed(Routes.homework)),
      (Icons.account_balance_wallet_outlined, 'Dues', AppColors.secondryColor, () => Get.toNamed(Routes.dues)),
      (Icons.schedule_rounded, 'Timetable', AppColors.purple, () => Get.toNamed(Routes.timetable)),
    ];

    return Obx(() {
      final student = students.selectedStudent;
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ScreenHeader(
            title: 'All services',
            caption: 'Everything your family needs',
            selectLabel: student?.fullName,
            onSelectTap: () => Get.toNamed(Routes.studentSelector),
          ),
          const AppWeekDateStrip(),
          const SizedBox(height: AppSpacing.md),
          StatsRow(items: [
            ('${modules.length}', 'Services', null),
            ('${quickAccessTiles.length}', 'Quick access', null),
            ('${students.students.length}', 'Children linked', null),
          ]),
          const SizedBox(height: AppSpacing.lg),
          const SectionRow(title: 'Quick access'),
          if (student != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 640 ? 6 : 4;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: quickAccessTiles
                      .map((t) => _tile(t.$1, t.$2, t.$3, t.$4))
                      .toList(),
                );
              },
            ),
          const SizedBox(height: AppSpacing.lg),
          const SectionRow(title: 'All services'),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 640 ? 5 : 3;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                childAspectRatio: 0.95,
                children: modules.map((m) {
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: InkWell(
                      onTap: m.$3,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primaryColor.withOpacity(0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            m.$1,
                            const SizedBox(height: 8),
                            CustomText(
                                text: m.$2,
                                textAlign: TextAlign.center,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 17)),
              const SizedBox(height: 7),
              CustomText(
                  text: label,
                  textAlign: TextAlign.center,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
