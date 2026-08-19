import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/datesheet_controller.dart';

class DatesheetScreen extends GetView<DatesheetController> {
  const DatesheetScreen({super.key});

  TagStyle _statusStyle(String status) {
    switch (status) {
      case 'scheduled':
      case 'ongoing':
        return TagStyle.info;
      case 'completed':
      case 'result_published':
        return TagStyle.green;
      case 'cancelled':
        return TagStyle.red;
      default:
        return TagStyle.neutral;
    }
  }

  String _fmt(DateTime? d) => d == null ? '—' : '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
        text: 'Exam datesheet',
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      )),
      body: Obx(() {
        if (controller.loading.value && controller.assessments.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(withChip: false),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }

        final assessments = controller.assessments;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(title: 'Exam datesheet', caption: 'Upcoming and ongoing assessments'),
              const SizedBox(height: AppSpacing.lg),
              if (assessments.isEmpty)
                const AppEmptyView(
                  icon: Icons.event_note_outlined,
                  title: 'No exams scheduled',
                  subtitle: 'Scheduled assessments will appear here once published.',
                )
              else
                ...assessments.map((raw) {
                  final a = Map<String, dynamic>.from(raw as Map);
                  final title = a['title']?.toString() ?? 'Assessment';
                  final type = (a['type']?.toString() ?? '').replaceAll('_', ' ');
                  final term = a['term']?.toString();
                  final status = a['status']?.toString() ?? 'scheduled';
                  final subjects = (a['subjects'] as List<dynamic>?) ?? [];
                  final startDate = DateTime.tryParse(a['startDate']?.toString() ?? '');
                  final endDate = DateTime.tryParse(a['endDate']?.toString() ?? '');

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
                                    text: title,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: AppColors.primaryColor,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  CustomText(
                                    text: [if (type.isNotEmpty) type, if (term != null) term].join(' · '),
                                    color: AppColors.muted,
                                    fontSize: 9.5,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            AppTag(status.replaceAll('_', ' '), style: _statusStyle(status)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (subjects.isEmpty)
                          CustomText(
                            text: '${_fmt(startDate)} – ${_fmt(endDate)}',
                            color: AppColors.ink,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Column(
                            children: subjects.map((raw2) {
                              final s = Map<String, dynamic>.from(raw2 as Map);
                              final date = DateTime.tryParse(s['date']?.toString() ?? '');
                              final startTime = s['startTime']?.toString();
                              final duration = s['duration'];
                              final venue = s['venue']?.toString();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: CustomText(
                                        text: s['subject']?.toString() ?? '—',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                        color: AppColors.ink,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: CustomText(
                                        text: [
                                          _fmt(date),
                                          if (startTime != null) startTime,
                                          if (duration != null) '${duration}min',
                                          if (venue != null && venue.isNotEmpty) venue,
                                        ].join(' · '),
                                        color: AppColors.muted,
                                        fontSize: 9.5,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
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
