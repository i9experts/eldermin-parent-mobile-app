import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(parentApiProvider);
  return api.getNotifications();
});

const _notificationIcons = {
  'circular': Icons.campaign_outlined, 'consent': Icons.verified_user_outlined,
  'leave_decision': Icons.event_available_outlined, 'fee_due': Icons.account_balance_wallet_outlined,
  'homework': Icons.menu_book_outlined, 'result': Icons.bar_chart_rounded,
  'behaviour': Icons.emoji_events_outlined, 'message': Icons.chat_bubble_outline_rounded,
};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(parentApiProvider).markAllNotificationsRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorView(message: 'Could not load notifications', onRetry: () => ref.invalidate(notificationsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyView(icon: Icons.notifications_none_rounded, title: "You're all caught up", subtitle: 'New updates will appear here.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: items.map((n) {
                final isRead = n['isRead'] == true;
                return ListCardRow(
                  icon: _notificationIcons[n['type']] ?? Icons.notifications_outlined,
                  title: n['title'] ?? '',
                  subtitle: n['body'] ?? '',
                  trailing: isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
                  onTap: () async {
                    if (!isRead) {
                      await ref.read(parentApiProvider).markNotificationRead(n['_id']);
                      ref.invalidate(notificationsProvider);
                    }
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
