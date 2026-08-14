import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/models/student.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../home/home_shell.dart';

class StudentSelectorScreen extends ConsumerWidget {
  const StudentSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(myStudentsProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Select your child', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Welcome, ${authState.userName ?? 'Parent'}', style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: studentsAsync.when(
                  loading: () => const AppLoader(),
                  error: (err, _) => AppErrorView(message: err.toString().replaceFirst('ApiException: ', ''), onRetry: () => ref.invalidate(myStudentsProvider)),
                  data: (students) {
                    if (students.isEmpty) {
                      return const AppEmptyView(
                        icon: Icons.person_off_outlined,
                        title: 'No students linked to this account',
                        subtitle: "Contact your school's front office to have your child's profile linked to this WhatsApp number.",
                      );
                    }
                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return _StudentTile(
                          student: s,
                          onTap: () {
                            ref.read(selectedStudentIdProvider.notifier).state = s.id;
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  const _StudentTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.blue, AppColors.sky]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(student.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text('Grade ${student.gradeSection}', style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        ],
      ),
    );
  }
}
