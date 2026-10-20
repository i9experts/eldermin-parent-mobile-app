import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../students/controllers/student_controller.dart';
import '../controllers/home_dashboard_controller.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = Get.find<StudentController>();
    final controller = Get.put(HomeDashboardController());
    final auth = Get.find<AuthController>();

    return Obx(() {
      final student = students.selectedStudent;
      if (student == null) {
        return const AppEmptyView(
            icon: Icons.person_off_outlined,
            title: 'No child selected',
            subtitle: 'Tap the profile at the top to choose a child.');
      }

      return RefreshIndicator(
        onRefresh: () => controller.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Obx(() {
              final fullName = auth.userName.value;
              final firstName =
                  (fullName != null && fullName.trim().isNotEmpty)
                      ? fullName.trim().split(RegExp(r'\s+')).first
                      : null;
              return ScreenHeader(
                title: firstName != null
                    ? 'Good morning, $firstName'
                    : 'Good morning',
                caption: DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                selectLabel: 'Today',
              );
            }),
            const AppWeekDateStrip(),
            const SizedBox(height: AppSpacing.lg),
            Obx(() {
              if (controller.attendanceLoading.value)
                return const AppShimmer(child: ShimmerHeroCardSkeleton());
              if (controller.attendanceError.value != null) {
                return AppErrorView(
                    message: controller.attendanceError.value!,
                    onRetry: controller.refresh);
              }
              final records = controller.attendance;
              final total = records.length;
              final present =
                  records.where((r) => r['status'] == 'present').length;
              final pct = total == 0 ? 0 : ((present / total) * 100).round();
              return HeroCard(
                kicker: "${student.firstName}'s day at a glance",
                value: total == 0 ? '—' : '$pct%',
                trend: total == 0
                    ? 'No attendance recorded yet'
                    : (pct >= 90
                        ? 'Strong attendance this month'
                        : 'Keep an eye on attendance'),
                percent: pct,
                metrics: [
                  (total == 0 ? '—' : '$pct%', 'Attendance'),
                  controller.homeworkLoading.value
                      ? ('—', 'Homework')
                      : ('${controller.homework.length}', 'Homework'),
                  controller.duesLoading.value
                      ? ('—', 'Fees')
                      : (
                          controller.dues.any((x) => (x['balanceDue'] ?? 0) > 0)
                              ? 'Due'
                              : 'Clear',
                          'Fees'
                        ),
                ],
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            const SectionRow(title: 'Quick access'),
            _QuickAccessGrid(studentId: student.id),
            const SizedBox(height: AppSpacing.lg),
            SectionRow(
                title: "Today's priority",
                onSeeAll: () => Get.toNamed(Routes.homework)),
            Obx(() {
              if (controller.homeworkLoading.value) {
                return AppShimmer(child: Column(children: shimmerListRows(3)));
              }
              if (controller.homeworkError.value != null)
                return const SizedBox.shrink();
              final pending = controller.homework
                  .where((h) =>
                      h['status'] != 'graded' && h['status'] != 'submitted')
                  .take(3)
                  .toList();
              if (pending.isEmpty) {
                return const AppEmptyView(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'All caught up',
                    subtitle: 'No pending homework right now.');
              }
              return Column(
                children: pending.map((h) {
                  final due = h['dueDate'] != null
                      ? DateTime.tryParse(h['dueDate'].toString())
                      : null;
                  return ListCardRow(
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.amber,
                    title: h['subject'] ?? h['title'] ?? 'Homework',
                    subtitle: h['title'] ?? '',
                    trailing: due != null
                        ? AppTag('Due ${due.day}/${due.month}',
                            style: TagStyle.amber)
                        : null,
                  );
                }).toList(),
              );
            }),
            Obx(() {
              if (controller.eventsLoading.value) return const SizedBox.shrink();
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final upcoming = controller.events
                  .cast<Map>()
                  .where((e) {
                    final d = e['startDate'] != null
                        ? DateTime.tryParse(e['startDate'].toString())
                        : null;
                    return d == null || !d.isBefore(today);
                  })
                  .toList()
                ..sort((a, b) {
                  final da = DateTime.tryParse(a['startDate']?.toString() ?? '') ??
                      DateTime(9999);
                  final db = DateTime.tryParse(b['startDate']?.toString() ?? '') ??
                      DateTime(9999);
                  return da.compareTo(db);
                });
              if (upcoming.isEmpty) return const SizedBox.shrink();
              final e = upcoming.first;
              final date = e['startDate'] != null
                  ? DateTime.tryParse(e['startDate'].toString())
                  : null;
              final subtitleParts = [
                if (date != null) '${date.day}/${date.month}/${date.year}',
                if (e['venue'] != null) e['venue'].toString(),
              ];
              return ListCardRow(
                icon: Icons.calendar_month_rounded,
                iconColor: AppColors.purple,
                title: e['title']?.toString() ?? 'School event',
                subtitle: subtitleParts.isEmpty
                    ? 'Upcoming'
                    : subtitleParts.join(' • '),
                trailing: AppTag((e['category'] ?? 'event').toString()),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final String studentId;
  const _QuickAccessGrid({required this.studentId});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.check_circle_outline_rounded,
        'Attendance',
        AppColors.blue,
        () => Get.toNamed(Routes.attendance)
      ),
      (
        Icons.menu_book_rounded,
        'Homework',
        AppColors.amber,
        () => Get.toNamed(Routes.homework)
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Pay fees',
        AppColors.secondryColor,
        () => Get.toNamed(Routes.dues)
      ),
      (
        Icons.schedule_rounded,
        'Timetable',
        AppColors.purple,
        () => Get.toNamed(Routes.timetable)
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth >= 640 ? 6 : 4;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
        children: items.map((item) {
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: item.$4,
              borderRadius: BorderRadius.circular(17),
              splashColor: item.$3.withOpacity(0.12),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(17)),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: item.$3.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(item.$1, color: item.$3, size: 17),
                    ),
                    const SizedBox(height: 7),
                    CustomText(
                        text: item.$2,
                        textAlign: TextAlign.center,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
