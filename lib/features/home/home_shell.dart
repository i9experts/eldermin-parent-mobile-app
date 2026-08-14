import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/models/student.dart';
import '../../core/theme/app_theme.dart';
import '../students/student_selector_screen.dart';
import '../notifications/notifications_screen.dart';
import '../more/more_screen.dart';
import 'home_dashboard_screen.dart';
import '../results/results_screen.dart';
import '../events/events_calendar_screen.dart';
import '../messages/messages_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tabIndex = 0;

  static const _tabs = [
    HomeDashboardScreen(),
    ResultsScreen(),
    EventsCalendarScreen(),
    MessagesScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(selectedStudentProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentSelectorScreen())),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.white, Color(0xFFD9EAFA)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                ),
                child: Center(child: Text(student?.initials ?? '--', style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 12))),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: Text(student?.fullName ?? 'Select child', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded, color: Colors.white70, size: 16),
                  ]),
                  if (student != null)
                    Text('Grade ${student.gradeSection}', style: const TextStyle(fontSize: 10, color: Color(0xFFBCD3E5))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white.withOpacity(0.13))),
                child: Stack(children: [
                  const Center(child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20)),
                  Positioned(right: 8, top: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle))),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'More'),
        ],
      ),
    );
  }
}
