import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart' show TagStyle;
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../controllers/profile_controller.dart';

/// Student profile (read-only). Teacher pattern: `design-kit-v1` `profile_screen.dart:34-49` (a list of header, details cards and
/// rows), header avatar + name `:56-72`, label / value rows in an [AppCard] `:148-164` (here [AppKeyValueRow]). Unlike the teacher
/// app, a field the school has not filled in still shows "-" (the parent app always did), so no information line disappears.
class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Student profile'),
      body: Obx(() {
        if (controller.loading.value && controller.profile.value == null) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(),
                const ShimmerProfileHeaderSkeleton(),
                const SizedBox(height: EmSpacing.s12),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: EmSpacing.s12),
                const ShimmerProgressCardSkeleton(),
                const SizedBox(height: EmSpacing.s12),
                ...shimmerListRows(3),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }
        final p = controller.profile.value;
        if (p == null) {
          return const AppEmptyView(icon: Icons.person_off_outlined, title: 'No profile on file');
        }

        final firstName = p['firstName']?.toString() ?? '';
        final lastName = p['lastName']?.toString() ?? '';
        final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
        final grade = p['currentGrade']?.toString() ?? '';
        final section = p['currentSection']?.toString();
        final roll = p['currentRollNumber']?.toString();
        final status = p['status']?.toString() ?? 'active';
        final dob = DateTime.tryParse(p['dateOfBirth']?.toString() ?? '');
        final bloodGroup = (p['medical'] is Map) ? (p['medical']['bloodGroup']?.toString()) : null;
        final guardians = (p['guardians'] as List<dynamic>?) ?? [];
        final documents = (p['documents'] as List<dynamic>?) ?? [];

        final coreFields = [firstName, lastName, grade, p['admissionNumber']?.toString(), p['dateOfBirth']?.toString(), p['gender']?.toString(), bloodGroup];
        final filled = coreFields.where((f) => f != null && f.isNotEmpty).length;
        final completeness = ((filled / coreFields.length) * 100).round();

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              const ScreenIntro(caption: 'Identity, contacts and record health', selectLabel: 'Current year'),
              AppCard(
                child: Column(
                  children: [
                    EmAvatar(
                      key: const Key('profile_avatar'),
                      initials: initials.isEmpty ? '—' : initials,
                      imageUrl: (p['photoUrl'] ?? p['photo'])?.toString(),
                      size: 96,
                    ),
                    const SizedBox(height: EmSpacing.s12),
                    Text('$firstName $lastName'.trim(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.heading.copyWith(color: EmColors.ink)),
                    const SizedBox(height: EmSpacing.s4),
                    Text(
                      [
                        if (grade.isNotEmpty) 'Grade $grade',
                        if (section != null && section.isNotEmpty) 'Section $section',
                        if (roll != null && roll.isNotEmpty) 'Roll $roll',
                      ].join(' • '),
                      textAlign: TextAlign.center,
                      style: EmType.label.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: EmSpacing.s8),
                    AppTag(status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '), style: status == 'active' ? TagStyle.green : TagStyle.neutral),
                  ],
                ),
              ),
              StatsRow(items: [
                ('$completeness%', 'Profile complete', null),
                ('${guardians.length}', 'Guardians', null),
                ('${documents.length}', 'Documents', null),
              ]),
              const SizedBox(height: EmSpacing.s12),
              if (completeness < 100)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Profile completeness', style: EmType.label.copyWith(color: EmColors.ink))),
                          AppTag('$completeness%', style: TagStyle.amber),
                        ],
                      ),
                      const SizedBox(height: EmSpacing.s12),
                      AppProgressBar(percent: completeness, color: EmColors.accent),
                    ],
                  ),
                ),
              const SectionRow(title: 'Record details'),
              AppCard(
                child: Column(
                  children: [
                    AppKeyValueRow('Admission number', p['admissionNumber']?.toString() ?? '—'),
                    AppKeyValueRow('Date of birth', dob != null ? '${dob.day}/${dob.month}/${dob.year}' : '—'),
                    AppKeyValueRow('Gender', p['gender']?.toString() ?? '—'),
                    AppKeyValueRow('Blood group', bloodGroup ?? '—'),
                    AppKeyValueRow('House group', p['houseGroup']?.toString() ?? '—'),
                    AppKeyValueRow('Class teacher', p['classTeacher']?.toString() ?? '—'),
                  ],
                ),
              ),
              if (guardians.isNotEmpty) ...[
                const SizedBox(height: EmSpacing.s8),
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
                    trailing: (g['isPrimary'] == true) ? const AppTag('Primary', style: TagStyle.info) : null,
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
