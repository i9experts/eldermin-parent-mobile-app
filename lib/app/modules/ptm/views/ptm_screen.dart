import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/ptm_controller.dart';

class PtmScreen extends GetView<PtmController> {
  const PtmScreen({super.key});

  TagStyle _statusStyle(String status) {
    switch (status) {
      case 'confirmed':
        return TagStyle.info;
      case 'completed':
        return TagStyle.green;
      case 'cancelled':
      case 'no_show':
        return TagStyle.red;
      default:
        return TagStyle.amber; // requested
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Parent-teacher meetings',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      body: Obx(() {
        if (controller.loading.value && controller.meetings.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(withChip: false),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(5),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }

        final meetings = controller.meetings;
        final completed = meetings.where((m) => Map<String, dynamic>.from(m as Map)['status'] == 'completed').length;
        final upcoming = meetings
            .where((m) => ['requested', 'confirmed'].contains(Map<String, dynamic>.from(m as Map)['status']))
            .length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(title: 'Parent-teacher meetings', caption: 'Requests and meeting history'),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${meetings.length}', 'Total', null),
                ('$upcoming', 'Upcoming', null),
                ('$completed', 'Completed', null),
              ]),
              const SizedBox(height: AppSpacing.lg),
              if (meetings.isEmpty)
                const AppEmptyView(
                  icon: Icons.groups_outlined,
                  title: 'No meetings yet',
                  subtitle: 'Parent-teacher meeting requests will appear here.',
                )
              else
                ...meetings.map((raw) {
                  final m = Map<String, dynamic>.from(raw as Map);
                  final teacherName = m['teacherName']?.toString() ?? 'Teacher';
                  final status = m['status']?.toString() ?? 'requested';
                  final date = DateTime.tryParse(m['scheduledDate']?.toString() ?? '');
                  final startTime = m['startTime']?.toString();
                  final endTime = m['endTime']?.toString();
                  final discussionPoints = (m['discussionPoints'] as List<dynamic>?) ?? [];
                  final meetingNotes = m['meetingNotes']?.toString();
                  final actionItems = (m['actionItems'] as List<dynamic>?) ?? [];

                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                      text: teacherName,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.primaryColor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  CustomText(
                                    text: [
                                      if (date != null) '${date.day}/${date.month}/${date.year}',
                                      if (startTime != null) '$startTime${endTime != null ? '–$endTime' : ''}',
                                    ].join(' · '),
                                    color: AppColors.muted,
                                    fontSize: 9.5,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            AppTag(
                              status.replaceAll('_', ' '),
                              style: _statusStyle(status),
                            ),
                          ],
                        ),
                        if (discussionPoints.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const CustomText(
                              text: 'Discussion points',
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              color: AppColors.primaryColor),
                          const SizedBox(height: 4),
                          ...discussionPoints.map((p) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: CustomText(
                                    text: '• ${p.toString()}',
                                    color: AppColors.ink,
                                    fontSize: 11),
                              )),
                        ],
                        if (meetingNotes != null && meetingNotes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const CustomText(
                              text: 'Notes',
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              color: AppColors.primaryColor),
                          const SizedBox(height: 4),
                          CustomText(
                              text: meetingNotes,
                              color: AppColors.ink,
                              fontSize: 11),
                        ],
                        if (actionItems.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const CustomText(
                              text: 'Action items',
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              color: AppColors.primaryColor),
                          const SizedBox(height: 6),
                          ...actionItems.map((raw2) {
                            final item = Map<String, dynamic>.from(raw2 as Map);
                            final done = item['status']?.toString() == 'done';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomText(
                                        text: item['description']?.toString() ?? '',
                                        color: AppColors.ink,
                                        fontSize: 11,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  AppTag(done ? 'Done' : 'Pending', style: done ? TagStyle.green : TagStyle.neutral),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
