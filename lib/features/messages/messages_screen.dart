import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final threadsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(parentApiProvider);
  return api.getThreads();
});

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(threadsProvider);

    return asyncData.when(
      loading: () => const AppLoader(),
      error: (e, _) => AppErrorView(message: 'Could not load messages', onRetry: () => ref.invalidate(threadsProvider)),
      data: (threads) {
        if (threads.isEmpty) {
          return const AppEmptyView(icon: Icons.chat_bubble_outline_rounded, title: 'No conversations yet', subtitle: "Messages from your child's teachers and the school office will appear here.");
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(threadsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: threads.map((t) {
              final lastAt = t['lastMessageAt'] != null ? DateTime.tryParse(t['lastMessageAt'].toString()) : null;
              final unread = t['guardianHasUnread'] == true;
              return AppCard(
                child: Row(children: [
                  Container(
                    width: 39, height: 39,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blue, AppColors.sky]), borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text((t['staffName'] ?? '?').toString().substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11))),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(t['staffName'] ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.navy))),
                          if (lastAt != null) Text('${lastAt.hour}:${lastAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.faint, fontSize: 9)),
                        ]),
                        const SizedBox(height: 3),
                        Text(t['lastMessagePreview'] ?? '', style: TextStyle(color: unread ? AppColors.ink : AppColors.muted, fontSize: 10.5, fontWeight: unread ? FontWeight.w700 : FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (unread) Container(margin: const EdgeInsets.only(left: 6), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
                ]),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
