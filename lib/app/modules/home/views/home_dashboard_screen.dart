import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/design/design.dart';
import '../../../../core/utils/greeting.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/em_tile_grid.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../students/controllers/student_controller.dart';
import '../controllers/home_dashboard_controller.dart';

/// Home tab (the teacher Home pattern): the greeting header and the child switcher live in the shell; this is today's
/// date and independent dashboard sections, each with its own loading / error / empty state. Pull to refresh.
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.screenH, EmSpacing.s8, EmSpacing.screenH, EmSpacing.s24),
          children: [
            Obx(() {
              final fullName = auth.userName.value;
              final firstName = (fullName != null && fullName.trim().isNotEmpty) ? fullName.trim().split(RegExp(r'\s+')).first : null;
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        firstName != null ? '${greetingFor(uiNow())}, $firstName' : greetingFor(uiNow()),
                        key: const Key('greeting_name'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: EmType.heading.copyWith(color: EmColors.ink)),
                    Text(DateFormat('EEEE, d MMMM yyyy').format(uiNow()),
                        key: const Key('greeting_date'), style: EmType.body.copyWith(color: EmColors.textSecondary)),
                  ],
                ),
              );
            }),
            Obx(() {
              if (controller.attendanceLoading.value) {
                return const AppShimmer(child: ShimmerHeroCardSkeleton());
              }
              if (controller.attendanceError.value != null) {
                return AppErrorView(message: controller.attendanceError.value!, onRetry: controller.refresh);
              }
              final records = controller.attendance;
              final total = records.length;
              final present = records.where((r) => r['status'] == 'present' || r['status'] == 'late').length;
              final pct = total == 0 ? 0 : ((present / total) * 100).round();
              return HeroCard(
                key: const Key('home_hero'),
                kicker: "${student.firstName}'s day at a glance",
                value: total == 0 ? '—' : '$pct%',
                trend: total == 0
                    ? 'No attendance recorded yet'
                    : (pct >= 90 ? 'Strong attendance this month' : 'Keep an eye on attendance'),
                trendWarn: total != 0 && pct < 90,
                percent: pct,
                metrics: [
                  (total == 0 ? '—' : '$pct%', 'Attendance'),
                  controller.homeworkLoading.value ? ('—', 'Homework') : ('${controller.homework.length}', 'Homework'),
                  controller.duesLoading.value
                      ? ('—', 'Fees')
                      : (controller.dues.any((x) => (x['balanceDue'] ?? 0) > 0) ? 'Due' : 'Clear', 'Fees'),
                ],
                metricIcons: const [Icons.check_circle_outline_rounded, Icons.menu_book_rounded, Icons.account_balance_wallet_outlined],
              );
            }),
            const SizedBox(height: EmSpacing.s16),
            const SectionRow(title: 'Quick access'),
            _QuickAccessGrid(studentId: student.id),
            const SizedBox(height: EmSpacing.s16),
            SectionRow(title: "Today's priority", onSeeAll: () => Get.toNamed(Routes.homework)),
            Obx(() {
              if (controller.homeworkLoading.value) {
                return AppShimmer(key: const Key('section_loading'), child: Column(children: shimmerListRows(3)));
              }
              if (controller.homeworkError.value != null) return const SizedBox.shrink();
              final pending = controller.homework
                  .where((h) => !['submitted', 'late', 'graded'].contains((h['mySubmission'] is Map ? h['mySubmission']['status'] : null)))
                  .take(3)
                  .toList();
              if (pending.isEmpty) {
                return const _InfoCard(
                    key: Key('section_empty'), icon: Icons.check_circle_outline_rounded, title: 'All caught up', subtitle: 'No pending homework right now.');
              }
              return Column(
                children: pending.map((h) {
                  final due = h['dueDate'] != null ? DateTime.tryParse(h['dueDate'].toString()) : null;
                  return ListCardRow(
                    icon: Icons.menu_book_rounded,
                    iconColor: EmColors.accent,
                    title: h['subject'] ?? h['title'] ?? 'Homework',
                    subtitle: h['title'] ?? '',
                    trailing: due != null ? AppTag('Due ${due.day}/${due.month}', style: TagStyle.amber) : null,
                  );
                }).toList(),
              );
            }),
            Obx(() {
              if (controller.eventsLoading.value) return const SizedBox.shrink();
              final now = uiNow();
              final today = DateTime(now.year, now.month, now.day);
              final upcoming = controller.events.cast<Map>().where((e) {
                final d = e['startDate'] != null ? DateTime.tryParse(e['startDate'].toString()) : null;
                return d == null || !d.isBefore(today);
              }).toList()
                ..sort((a, b) {
                  final da = DateTime.tryParse(a['startDate']?.toString() ?? '') ?? DateTime(9999);
                  final db = DateTime.tryParse(b['startDate']?.toString() ?? '') ?? DateTime(9999);
                  return da.compareTo(db);
                });
              if (upcoming.isEmpty) return const SizedBox.shrink();
              final e = upcoming.first;
              final date = e['startDate'] != null ? DateTime.tryParse(e['startDate'].toString()) : null;
              final subtitleParts = [
                if (date != null) '${date.day}/${date.month}/${date.year}',
                if (e['venue'] != null) e['venue'].toString(),
              ];
              return ListCardRow(
                icon: Icons.calendar_month_rounded,
                iconColor: EmColors.statusLeave,
                title: e['title']?.toString() ?? 'School event',
                subtitle: subtitleParts.isEmpty ? 'Upcoming' : subtitleParts.join(' • '),
                trailing: AppTag((e['category'] ?? 'event').toString()),
              );
            }),
          ],
        ),
      );
    });
  }
}

/// A one-line empty message in a card (the teacher Home sections' empty state).
class _InfoCard extends StatelessWidget {
  const _InfoCard({super.key, required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => EmCard(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: EmColors.primaryTint, shape: BoxShape.circle),
            child: ExcludeSemantics(child: Icon(icon, color: EmColors.primary, size: 22)),
          ),
          const SizedBox(width: EmSpacing.s12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: EmType.bodyLarge.copyWith(color: EmColors.ink)),
              if (subtitle != null) Text(subtitle!, style: EmType.label.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
            ]),
          ),
        ]),
      );
}

/// Four shortcuts on the kit tile grid (two per row, four on wide screens, one at large text sizes).
class _QuickAccessGrid extends StatelessWidget {
  final String studentId;
  const _QuickAccessGrid({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return EmTileGrid(tiles: [
      EmTile(label: 'Attendance', icon: Icons.check_circle_outline_rounded, color: EmColors.primary, onTap: () => Get.toNamed(Routes.attendance), tileKey: const Key('quick_Attendance')),
      EmTile(label: 'Homework', icon: Icons.menu_book_rounded, color: EmColors.accent, onTap: () => Get.toNamed(Routes.homework), tileKey: const Key('quick_Homework')),
      EmTile(label: 'Fees & dues', icon: Icons.account_balance_wallet_outlined, color: EmColors.success, onTap: () => Get.toNamed(Routes.dues), tileKey: const Key('quick_Fees & dues')),
      EmTile(label: 'Timetable', icon: Icons.schedule_rounded, color: EmColors.statusLeave, onTap: () => Get.toNamed(Routes.timetable), tileKey: const Key('quick_Timetable')),
    ]);
  }
}
