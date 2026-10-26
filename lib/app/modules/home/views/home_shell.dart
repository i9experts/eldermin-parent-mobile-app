import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../config/app_icons.dart';
import '../../../routes/app_routes.dart';
import '../../students/controllers/student_controller.dart';
import '../../more/views/more_screen.dart';
import '../../results/views/results_screen.dart';
import '../../events/views/events_calendar_screen.dart';
import '../../messages/views/messages_screen.dart';
import '../controllers/home_shell_controller.dart';
import 'home_dashboard_screen.dart';

/// App shell (the teacher shell pattern): the header (EmGreetingHeader) over the five tabs and the kit bottom navigation.
/// The header holds the child switcher (avatar + child's name, tap opens the child selector) and the notifications
/// bell. The bell has no unread dot: no controller that is alive at the shell exposes an unread-notification state
/// (NotificationsController only exists while its own screen is open), and the UI-only redesign adds no data source.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _tabs = [
    HomeDashboardScreen(),
    ResultsScreen(),
    EventsCalendarScreen(),
    MessagesScreen(),
    MoreScreen(),
  ];

  /// Key of the bottom navigation bar (tests and finders use this, not its type).
  static const navKey = Key('app_shell_nav');

  @override
  Widget build(BuildContext context) {
    final shell = Get.put(HomeShellController());
    final students = Get.find<StudentController>();

    return EmScaffold(
      extendBody: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.screenH, EmSpacing.s12, EmSpacing.screenH, EmSpacing.s4),
              child: Obx(() {
                final student = students.selectedStudent;
                return EmGreetingHeader(
                  key: const Key('shell_header'),
                  // the muted line is the child's grade (as under the name before); the time-of-day greeting is on the Home tab
                  greeting: student == null ? 'Choose a child' : 'Grade ${student.gradeSection}',
                  name: student?.fullName ?? 'Select child',
                  avatar: _ChildAvatar(initials: student?.initials ?? '--', imageUrl: student?.photoUrl),
                  // the child switcher: same destination as before
                  onTap: () => Get.toNamed(Routes.studentSelector),
                  trailing: EmIconCircleButton(
                    key: const Key('bell_button'),
                    icon: Icons.notifications_none_rounded,
                    semanticLabel: 'Notifications',
                    onTap: () => Get.toNamed(Routes.notifications),
                  ),
                );
              }),
            ),
            Expanded(child: Obx(() => IndexedStack(index: shell.tabIndex.value, children: _tabs))),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() => EmBottomNav(
            key: navKey,
            currentIndex: shell.tabIndex.value,
            onTap: shell.changeTab,
            items: const [
              EmNavItem(svgIcon: AppIcons.home, label: 'Home'),
              EmNavItem(svgIcon: AppIcons.anylaticsIcon, label: 'Progress'),
              EmNavItem(svgIcon: AppIcons.calenderIcon, label: 'Calendar'),
              EmNavItem(svgIcon: AppIcons.messageIcon, label: 'Messages'),
              EmNavItem(svgIcon: AppIcons.more, label: 'More'),
            ],
          )),
    );
  }
}

/// The selected child's avatar with a small chevron badge: it is the child switcher's affordance.
class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({required this.initials, this.imageUrl});
  final String initials;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        EmAvatar(initials: initials, imageUrl: imageUrl),
        PositionedDirectional(
          bottom: -2,
          end: -2,
          child: Container(
            key: const Key('child_switch_badge'),
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: EmColors.surface, shape: BoxShape.circle, border: Border.all(color: EmColors.border)),
            child: const ExcludeSemantics(child: Icon(Icons.expand_more_rounded, size: 16, color: EmColors.primaryDark)),
          ),
        ),
      ],
    );
  }
}
