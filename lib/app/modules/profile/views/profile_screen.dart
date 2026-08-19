import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(text: label, color: AppColors.muted, fontSize: 10.5),
          Flexible(
            child: CustomText(
                text: value,
                color: AppColors.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Student profile',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      body: Obx(() {
        if (controller.loading.value && controller.profile.value == null) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerDateStripSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: const Color(0xFFE3EAF0))),
                  child: const Column(
                    children: [
                      ShimmerCircle(size: 66),
                      SizedBox(height: 10),
                      ShimmerBone(width: 140, height: 16, radius: 6),
                      SizedBox(height: 8),
                      ShimmerBone(width: 100, height: 10, radius: 5),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.md),
                const ShimmerChartSkeleton(),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(3),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }
        final p = controller.profile.value;
        if (p == null)
          return const AppEmptyView(
              icon: Icons.person_off_outlined, title: 'No profile on file');

        final firstName = p['firstName']?.toString() ?? '';
        final lastName = p['lastName']?.toString() ?? '';
        final initials =
            '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                .toUpperCase();
        final grade = p['currentGrade']?.toString() ?? '';
        final section = p['currentSection']?.toString();
        final roll = p['currentRollNumber']?.toString();
        final status = p['status']?.toString() ?? 'active';
        final dob = DateTime.tryParse(p['dateOfBirth']?.toString() ?? '');
        final bloodGroup = (p['medical'] is Map)
            ? (p['medical']['bloodGroup']?.toString())
            : null;
        final guardians = (p['guardians'] as List<dynamic>?) ?? [];
        final documents = (p['documents'] as List<dynamic>?) ?? [];

        final coreFields = [
          firstName,
          lastName,
          grade,
          p['admissionNumber']?.toString(),
          p['dateOfBirth']?.toString(),
          p['gender']?.toString(),
          bloodGroup
        ];
        final filled =
            coreFields.where((f) => f != null && f.isNotEmpty).length;
        final completeness = ((filled / coreFields.length) * 100).round();

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(
                title: 'Student profile',
                caption: 'Identity, contacts and record health',
                selectLabel: 'Current year',
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFD9EAFA)]),
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.12), width: 2),
                      ),
                      child: Center(
                          child: CustomText(
                              text: initials.isEmpty ? '—' : initials,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                    ),
                    const SizedBox(height: 10),
                    CustomText(
                        text: '$firstName $lastName'.trim(),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    CustomText(
                        text: [
                          if (grade.isNotEmpty) 'Grade $grade',
                          if (section != null && section.isNotEmpty)
                            'Section $section',
                          if (roll != null && roll.isNotEmpty) 'Roll $roll',
                        ].join(' • '),
                        color: AppColors.muted,
                        fontSize: 10.5,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    AppTag(
                        status[0].toUpperCase() +
                            status.substring(1).replaceAll('_', ' '),
                        style: status == 'active'
                            ? TagStyle.green
                            : TagStyle.neutral),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StatsRow(items: [
                ('$completeness%', 'Profile complete', null),
                ('${guardians.length}', 'Guardians', null),
                ('${documents.length}', 'Documents', null),
              ]),
              const SizedBox(height: AppSpacing.md),
              if (completeness < 100)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                              text: 'Profile completeness',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.primaryColor),
                          AppTag('$completeness%', style: TagStyle.amber),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppProgressBar(
                          percent: completeness, color: AppColors.amber),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              const SectionRow(title: 'Record details'),
              AppCard(
                child: Column(
                  children: [
                    _row('Admission number',
                        p['admissionNumber']?.toString() ?? '—'),
                    const Divider(),
                    _row(
                        'Date of birth',
                        dob != null
                            ? '${dob.day}/${dob.month}/${dob.year}'
                            : '—'),
                    const Divider(),
                    _row('Gender', p['gender']?.toString() ?? '—'),
                    const Divider(),
                    _row('Blood group', bloodGroup ?? '—'),
                    const Divider(),
                    _row('House group', p['houseGroup']?.toString() ?? '—'),
                    const Divider(),
                    _row('Class teacher', p['classTeacher']?.toString() ?? '—'),
                  ],
                ),
              ),
              if (guardians.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const SectionRow(title: 'Guardians & contacts'),
                ...guardians.map((raw) {
                  final g = Map<String, dynamic>.from(raw as Map);
                  return ListCardRow(
                    icon: Icons.person_outline_rounded,
                    title: g['name']?.toString() ?? 'Guardian',
                    subtitle: [
                      if (g['relation'] != null) g['relation'].toString(),
                      if (g['phone'] != null) g['phone'].toString(),
                    ].join(' • '),
                    trailing: (g['isPrimary'] == true)
                        ? const AppTag('Primary', style: TagStyle.info)
                        : null,
                  );
                }),
              ],
            ],
          ),
        );
      }),
    );
  }
}
