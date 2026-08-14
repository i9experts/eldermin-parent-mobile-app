import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/student.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../shared/coming_soon_screen.dart';
import '../notifications/notifications_screen.dart';
import '../dues/dues_screen.dart';
import '../timetable/timetable_screen.dart';
import '../homework/homework_screen.dart';
import '../attendance/attendance_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(selectedStudentProvider);

    final modules = <(IconData, String, Widget Function())>[
      (Icons.folder_outlined, 'Learning resources', () => const ComingSoonScreen(title: 'Learning Resources')),
      (Icons.local_library_outlined, 'Library', () => const ComingSoonScreen(title: 'Library')),
      (Icons.favorite_outline_rounded, 'Behaviour & Tarbiyah', () => const ComingSoonScreen(title: 'Behaviour & Tarbiyah')),
      (Icons.person_outline_rounded, 'Student profile', () => const ComingSoonScreen(title: 'Student Profile')),
      (Icons.medical_information_outlined, 'Medical', () => const ComingSoonScreen(title: 'Medical Information')),
      (Icons.description_outlined, 'Academic documents', () => const ComingSoonScreen(title: 'Academic Documents')),
      (Icons.verified_user_outlined, 'Consent', () => const ComingSoonScreen(title: 'Consent')),
      (Icons.event_available_outlined, 'My leaves', () => const ComingSoonScreen(title: 'My Leaves')),
      (Icons.event_note_outlined, 'Datesheet', () => const ComingSoonScreen(title: 'Exam Datesheet')),
      (Icons.campaign_outlined, 'Circulars', () => const ComingSoonScreen(title: 'Circulars')),
      (Icons.inbox_outlined, 'Inbox', () => const NotificationsScreen()),
      (Icons.chat_outlined, 'Feedback', () => const ComingSoonScreen(title: 'Send Feedback')),
      (Icons.switch_account_outlined, 'Switch user', () => const ComingSoonScreen(title: 'Switch Account')),
      (Icons.lock_outline_rounded, 'Privacy policy', () => const ComingSoonScreen(title: 'Privacy Policy')),
      (Icons.info_outline_rounded, 'About us', () => const ComingSoonScreen(title: 'About Eldermin')),
      (Icons.support_agent_outlined, 'Help', () => const ComingSoonScreen(title: 'Help & Support')),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SectionRow(title: 'Quick access'),
        if (student != null)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              _tile(context, Icons.check_circle_outline_rounded, 'Attendance', AppColors.blue, () => AttendanceScreen(studentId: student.id)),
              _tile(context, Icons.menu_book_rounded, 'Homework', AppColors.amber, () => HomeworkScreen(studentId: student.id)),
              _tile(context, Icons.account_balance_wallet_outlined, 'Dues', AppColors.green, () => DuesScreen(studentId: student.id)),
              _tile(context, Icons.schedule_rounded, 'Timetable', AppColors.purple, () => TimetableScreen(studentId: student.id)),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        const SectionRow(title: 'All services'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 0.95,
          children: modules.map((m) {
            return GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => m.$3())),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(17)),
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m.$1, color: AppColors.blue, size: 22),
                    const SizedBox(height: 8),
                    Text(m.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, Color color, Widget Function() builder) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => builder())),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(17)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 17)),
            const SizedBox(height: 7),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
