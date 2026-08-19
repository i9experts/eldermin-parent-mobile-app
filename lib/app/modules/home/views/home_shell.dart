import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../components/svg_icon.dart';
import '../../../components/custom_text.dart';
import '../../../config/app_icons.dart';
import '../../students/controllers/student_controller.dart';
import '../../more/views/more_screen.dart';
import '../../results/views/results_screen.dart';
import '../../events/views/events_calendar_screen.dart';
import '../../messages/views/messages_screen.dart';
import '../controllers/home_shell_controller.dart';
import 'home_dashboard_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _tabs = [
    HomeDashboardScreen(),
    ResultsScreen(),
    EventsCalendarScreen(),
    MessagesScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = Get.put(HomeShellController());
    final students = Get.find<StudentController>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: () => Get.toNamed(Routes.studentSelector),
          child: Obx(() {
            final student = students.selectedStudent;
            return Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFD9EAFA)]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.35), width: 2),
                  ),
                  child: Center(
                      child: CustomText(
                          text: student?.initials ?? '--',
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                            child: CustomText(
                                text: student?.fullName ?? 'Select child',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more_rounded,
                            color: Colors.white70, size: 16),
                      ]),
                      if (student != null)
                        CustomText(
                            text: 'Grade ${student.gradeSection}',
                            fontSize: 10,
                            color: const Color(0xFFBCD3E5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => Get.toNamed(Routes.notifications),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white.withOpacity(0.13))),
                child: Stack(children: [
                  const Center(
                      child: Icon(Icons.notifications_none_rounded,
                          color: Colors.white, size: 20)),
                  Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.amber, shape: BoxShape.circle))),
                ]),
              ),
            ),
          ),
        ],
      ),
      body:
          Obx(() => IndexedStack(index: shell.tabIndex.value, children: _tabs)),
      bottomNavigationBar: Obx(() {
        const icons = [
          AppIcons.home,
          AppIcons.anylaticsIcon,
          AppIcons.calenderIcon,
          AppIcons.messageIcon,
          AppIcons.more,
        ];
        const labels = ['Home', 'Progress', 'Calendar', 'Messages', 'More'];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, -6)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: shell.tabIndex.value,
              onTap: shell.changeTab,
              items: [
                for (var i = 0; i < icons.length; i++)
                  BottomNavigationBarItem(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: shell.tabIndex.value == i
                            ? AppColors.pale
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: SvgIcon(
                        assetName: icons[i],
                        size: 20,
                        color: shell.tabIndex.value == i
                            ? AppColors.blue
                            : AppColors.faint,
                      ),
                    ),
                    label: labels[i],
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
