import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/models/student.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/student_controller.dart';

/// The child switcher (opened from the shell header): picking a child calls the same controller method as before and
/// returns to the shell.
class StudentSelectorScreen extends StatelessWidget {
  const StudentSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = Get.find<StudentController>();
    final auth = Get.find<AuthController>();

    return EmScaffold(
      appBar: const EmAppBar(title: 'Select your child'),
      body: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() => EmCaptionLine('Welcome, ${auth.userName.value ?? 'Parent'}', maxLines: 1)),
            Expanded(
              child: Obx(() {
                if (students.loading.value && students.students.isEmpty) {
                  return AppShimmer(child: ListView(children: shimmerListRows(3)));
                }
                if (students.error.value != null && students.students.isEmpty) {
                  return AppErrorView(message: students.error.value!, onRetry: students.fetchMyStudents);
                }
                if (students.students.isEmpty) {
                  return const AppEmptyView(
                    icon: Icons.person_off_outlined,
                    title: 'No students linked to this account',
                    subtitle: "Contact your school's front office to have your child's profile linked to this WhatsApp number.",
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s24),
                  itemCount: students.students.length,
                  itemBuilder: (context, index) {
                    final s = students.students[index];
                    return _StudentTile(
                      student: s,
                      onTap: () {
                        students.selectStudent(s.id);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.row),
      child: EmListRow(
        key: Key('student_${student.id}'),
        leading: EmAvatar(initials: student.initials.isEmpty ? '—' : student.initials, imageUrl: student.photoUrl, size: 48),
        title: student.fullName,
        subtitle: 'Grade ${student.gradeSection}',
        trailing: const Icon(Icons.chevron_right_rounded, color: EmColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
