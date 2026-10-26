import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/em_tab_heading.dart';
import '../../../../core/widgets/em_tile_grid.dart';
import '../../../components/svg_icon.dart';
import '../../../config/app_icons.dart';
import '../../shared/views/coming_soon_screen.dart';
import '../../students/controllers/student_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// More tab root (teacher tab-root pattern: [TabHeading] + a list of sections, teacher `more_screen.dart:19-71`; the
/// child summary card follows the teacher's `_ProfileCard`, `more_screen.dart:75-106`). Every entry keeps its destination.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = Get.find<StudentController>();

    final modules = <(Widget, String, VoidCallback)>[
      (
        const Icon(Icons.auto_stories_outlined, color: EmColors.primary),
        'Class diary',
        () => Get.toNamed(Routes.diary)
      ),
      (
        const Icon(Icons.school_outlined, color: EmColors.primary),
        'My courses',
        () => Get.toNamed(Routes.courses)
      ),
      (
        const Icon(Icons.quiz_outlined, color: EmColors.primary),
        'Online quizzes',
        () => Get.toNamed(Routes.quizzes)
      ),
      (
        const Icon(Icons.folder_outlined, color: EmColors.primary),
        'Learning resources',
        () => Get.toNamed(Routes.learningResources)
      ),
      (
        const Icon(Icons.local_library_outlined, color: EmColors.primary),
        'Library',
        () => Get.toNamed(Routes.library)
      ),
      (
        const SvgIcon(assetName: AppIcons.behaviour, size: 22, color: EmColors.primary),
        'Behaviour & Tarbiyah',
        () => Get.toNamed(Routes.tarbiyah)
      ),
      (
        const SvgIcon(assetName: AppIcons.profileIcon, size: 22, color: EmColors.primary),
        'Student profile',
        () => Get.toNamed(Routes.profile)
      ),
      (
        const Icon(Icons.medical_information_outlined, color: EmColors.primary),
        'Medical',
        () => Get.toNamed(Routes.medical)
      ),
      (
        const Icon(Icons.description_outlined, color: EmColors.primary),
        'Academic documents',
        () => Get.toNamed(Routes.documents)
      ),
      (
        const SvgIcon(assetName: AppIcons.checkIcon, size: 22, color: EmColors.primary),
        'Consent',
        () => Get.toNamed(Routes.consent)
      ),
      (
        const Icon(Icons.event_available_outlined, color: EmColors.primary),
        'My leaves',
        () => Get.toNamed(Routes.leaves)
      ),
      (
        const Icon(Icons.favorite_outline, color: EmColors.primary),
        'Home tasks',
        () => Get.toNamed(Routes.homeTasks)
      ),
      (
        const SvgIcon(assetName: AppIcons.calenderIcon, size: 22, color: EmColors.primary),
        'Datesheet',
        () => Get.toNamed(Routes.datesheet)
      ),
      (
        const Icon(Icons.groups_outlined, color: EmColors.primary),
        'Parent-teacher meetings',
        () => Get.toNamed(Routes.ptm)
      ),
      (
        const SvgIcon(assetName: AppIcons.reportIcon, size: 22, color: EmColors.primary),
        'Circulars',
        () => Get.toNamed(Routes.circulars)
      ),
      (
        const SvgIcon(assetName: AppIcons.messageIcon, size: 22, color: EmColors.primary),
        'Inbox',
        () => Get.toNamed(Routes.notifications)
      ),
      (
        const SvgIcon(assetName: AppIcons.messageSendIcon, size: 22, color: EmColors.primary),
        'Feedback',
        () => Get.toNamed(Routes.feedback)
      ),
      (
        const Icon(Icons.switch_account_outlined, color: EmColors.primary),
        'Switch user',
        () => Get.to(() => const ComingSoonScreen(title: 'Switch Account'))
      ),
      (
        const SvgIcon(assetName: AppIcons.privacy, size: 22, color: EmColors.primary),
        'Privacy policy',
        () => Get.toNamed(Routes.privacyPolicy)
      ),
      (
        const SvgIcon(assetName: AppIcons.aboutIcon, size: 22, color: EmColors.primary),
        'About us',
        () => Get.toNamed(Routes.aboutUs)
      ),
      (
        const SvgIcon(assetName: AppIcons.faqIcon, size: 22, color: EmColors.primary),
        'Help',
        () => Get.toNamed(Routes.help)
      ),
      (
        const Icon(Icons.logout_rounded, color: EmColors.onErrorContainer),
        'Logout',
        () => _confirmLogout()
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
        padding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.screenH, EmSpacing.s8, EmSpacing.screenH, EmSpacing.s24),
        children: [
          const TabHeading(title: 'All services', caption: 'Everything your family needs'),
          const SizedBox(height: EmSpacing.s8),
          if (student != null) ...[
            // the child switcher (same destination as the shell header): who the app is showing
            EmCard(
              key: const Key('more_child_card'),
              elevated: true,
              onTap: () => Get.toNamed(Routes.studentSelector),
              padding: const EdgeInsetsDirectional.all(EmSpacing.s16),
              semanticLabel: 'Switch child, ${student.fullName}, Grade ${student.gradeSection}',
              child: Row(children: [
                EmAvatar(initials: student.initials.isEmpty ? '—' : student.initials, imageUrl: student.photoUrl, size: 56),
                const SizedBox(width: EmSpacing.s16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(student.fullName, maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.heading.copyWith(color: EmColors.ink)),
                    Text('Grade ${student.gradeSection}', maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.label.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
                    Text('Tap to switch child', style: EmType.caption.copyWith(color: EmColors.primary)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: EmColors.textSecondary),
              ]),
            ),
            const SizedBox(height: EmSpacing.s8),
            const SectionRow(title: 'Quick access'),
            EmTileGrid(tiles: [
              for (final t in quickAccessTiles) EmTile(label: t.$2, icon: t.$1, color: t.$3, onTap: t.$4, tileKey: Key('quick_${t.$2}')),
            ]),
            const SizedBox(height: EmSpacing.s16),
          ],
          const SectionRow(title: 'All services'),
          EmTileGrid(tiles: [
            for (final m in modules) EmTile(label: m.$2, leading: m.$1, destructive: m.$2 == 'Logout', onTap: m.$3, tileKey: Key('service_${m.$2}')),
          ]),
        ],
      );
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await Get.dialog<bool>(
      EmDialog(
        title: 'Logout',
        message: 'Are you sure you want to logout?',
        actions: [
          EmDialogAction(label: 'Cancel', onPressed: () => Get.back(result: false)),
          EmDialogAction(label: 'Logout', tone: EmDialogTone.destructive, onPressed: () => Get.back(result: true)),
        ],
      ),
    );
    if (confirmed == true) {
      await Get.find<AuthController>().logout();
    }
  }
}
