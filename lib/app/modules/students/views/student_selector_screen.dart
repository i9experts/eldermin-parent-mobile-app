import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/models/student.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/student_controller.dart';

class StudentSelectorScreen extends StatelessWidget {
  const StudentSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = Get.find<StudentController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              const CustomText(
                text: 'Select your child',
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
                letterSpacing: -0.75,
              ),
              const SizedBox(height: 4),
              Obx(() => CustomText(
                  text: 'Welcome, ${auth.userName.value ?? 'Parent'}',
                  color: AppColors.muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Obx(() {
                  if (students.loading.value && students.students.isEmpty) {
                    return AppShimmer(child: ListView(children: shimmerListRows(3)));
                  }
                  if (students.error.value != null &&
                      students.students.isEmpty) {
                    return AppErrorView(
                        message: students.error.value!,
                        onRetry: students.fetchMyStudents);
                  }
                  if (students.students.isEmpty) {
                    return const AppEmptyView(
                      icon: Icons.person_off_outlined,
                      title: 'No students linked to this account',
                      subtitle:
                          "Contact your school's front office to have your child's profile linked to this WhatsApp number.",
                    );
                  }
                  return ListView.builder(
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [AppColors.blue, AppColors.sky]),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(
                child: CustomText(
                    text: student.initials,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                    text: student.fullName,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                CustomText(
                    text: 'Grade ${student.gradeSection}',
                    color: AppColors.muted,
                    fontSize: 11.5,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        ],
      ),
    );
  }
}
