import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/messages_controller.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessagesController());

    return Obx(() {
      if (controller.loading.value && controller.threads.isEmpty) {
        return AppShimmer(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ShimmerScreenHeaderSkeleton(),
              const SizedBox(height: AppSpacing.lg),
              const ShimmerDateStripSkeleton(),
              const SizedBox(height: AppSpacing.md),
              const ShimmerStatsRowSkeleton(count: 2),
              const SizedBox(height: AppSpacing.md),
              const ShimmerChartSkeleton(),
              const SizedBox(height: AppSpacing.md),
              ...shimmerListRows(5),
            ],
          ),
        );
      }
      if (controller.error.value != null) {
        return AppErrorView(
            message: controller.error.value!, onRetry: controller.fetch);
      }

      final threads = controller.threads;
      final unreadCount =
          threads.where((t) => t['guardianHasUnread'] == true).length;
      final totalCount = threads.length;
      final readCount = totalCount - unreadCount;
      final healthPercent =
          totalCount == 0 ? 100 : ((readCount / totalCount) * 100).round();

      return RefreshIndicator(
        onRefresh: controller.fetch,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const ScreenHeader(
              title: 'Messages',
              caption: 'School conversations in one place',
              selectLabel: 'All messages',
            ),
            const AppWeekDateStrip(),
            const SizedBox(height: AppSpacing.md),
            if (threads.isEmpty)
              const AppEmptyView(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No conversations yet',
                  subtitle:
                      "Messages from your child's teachers and the school office will appear here.")
            else ...[
              StatsRow(items: [
                ('$unreadCount', 'Unread', null),
                ('$totalCount', 'Threads', null),
              ]),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                        text: 'Communication health',
                        color: AppColors.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800),
                    const SizedBox(height: 8),
                    CustomText(
                        text: '$readCount of $totalCount threads read',
                        color: AppColors.muted,
                        fontSize: 10),
                    const SizedBox(height: 8),
                    AppProgressBar(percent: healthPercent, color: AppColors.secondryColor),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...threads.map((t) {
            final lastAt = t['lastMessageAt'] != null
                ? DateTime.tryParse(t['lastMessageAt'].toString())
                : null;
            final unread = t['guardianHasUnread'] == true;
            return AppCard(
              child: Row(children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.blue, AppColors.sky]),
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(
                      child: CustomText(
                          text: (t['staffName'] ?? '?')
                              .toString()
                              .substring(0, 2)
                              .toUpperCase(),
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: CustomText(
                                text: t['staffName'] ?? 'Staff',
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        if (lastAt != null)
                          CustomText(
                              text:
                                  '${lastAt.hour}:${lastAt.minute.toString().padLeft(2, '0')}',
                              color: AppColors.faint,
                              fontSize: 9),
                      ]),
                      const SizedBox(height: 3),
                      CustomText(
                          text: t['lastMessagePreview'] ?? '',
                          color: unread ? AppColors.ink : AppColors.muted,
                          fontSize: 10.5,
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w400,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.amber, shape: BoxShape.circle)),
              ]),
            );
          }),
            ],
          ],
        ),
      );
    });
  }
}
