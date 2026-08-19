import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_text.dart';
import '../controllers/notifications_controller.dart';

const _notificationIcons = {
  'circular': Icons.campaign_outlined,
  'consent': Icons.verified_user_outlined,
  'leave_decision': Icons.event_available_outlined,
  'fee_due': Icons.account_balance_wallet_outlined,
  'homework': Icons.menu_book_outlined,
  'result': Icons.bar_chart_rounded,
  'behaviour': Icons.emoji_events_outlined,
  'message': Icons.chat_bubble_outline_rounded,
};

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
            text: 'Notifications',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await controller.markAllRead();
              if (ok) {
                CustomAppSnackbar.success('All notifications marked as read.');
              } else {
                CustomAppSnackbar.error('Could not update notifications. Please try again.');
              }
            },
            child: const CustomText(
                text: 'Mark all read', color: Colors.white, fontSize: 12),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.items.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: shimmerListRows(7),
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final items = controller.items;
        if (items.isEmpty) {
          return const AppEmptyView(
              icon: Icons.notifications_none_rounded,
              title: "You're all caught up",
              subtitle: 'New updates will appear here.');
        }
        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: items.map((n) {
              final isRead = n['isRead'] == true;
              return ListCardRow(
                icon: _notificationIcons[n['type']] ??
                    Icons.notifications_outlined,
                title: n['title'] ?? '',
                subtitle: n['body'] ?? '',
                trailing: isRead
                    ? null
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.amber, shape: BoxShape.circle)),
                onTap: () {
                  if (!isRead) controller.markRead(n['_id']);
                },
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}
