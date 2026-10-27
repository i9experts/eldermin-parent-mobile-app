import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/em_tab_heading.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/widgets/tab_state_list.dart';
import '../../../routes/app_routes.dart';
import '../controllers/messages_controller.dart';

/// Messages tab root (teacher tab-root pattern: [TabHeading] + [TabStateList], teacher `messages_screen.dart:19-62` and
/// `classes_screen.dart:59-72`; conversation rows follow the teacher's `ThreadRow`, `messages_screen.dart:67-129`).
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessagesController());

    return Obx(() {
      final threads = controller.threads;
      final loading = controller.loading.value && threads.isEmpty;
      final TabListState state;
      if (loading) {
        state = TabListState.loading;
      } else if (controller.error.value != null) {
        state = TabListState.error;
      } else if (threads.isEmpty) {
        state = TabListState.empty;
      } else {
        state = TabListState.data;
      }

      final unreadCount = threads.where((t) => t['guardianHasUnread'] == true).length;
      final totalCount = threads.length;
      final readCount = totalCount - unreadCount;
      final healthPercent = totalCount == 0 ? 100 : ((readCount / totalCount) * 100).round();

      return TabStateList(
        state: state,
        onRefresh: controller.fetch,
        header: const [
          TabHeading(title: 'Messages', caption: 'School conversations in one place'),
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
            child: Align(alignment: AlignmentDirectional.centerStart, child: EmChip.status(label: 'All messages', tone: EmTone.info)),
          ),
        ],
        skeleton: const [
          ShimmerStatsRowSkeleton(count: 2),
          SizedBox(height: EmSpacing.s12),
          ShimmerChartSkeleton(),
          SizedBox(height: EmSpacing.s12),
          ShimmerListRowSkeleton(),
          ShimmerListRowSkeleton(),
          ShimmerListRowSkeleton(),
          ShimmerListRowSkeleton(),
        ],
        errorMessage: controller.error.value,
        onRetry: controller.fetch,
        emptyIcon: Icons.chat_bubble_outline_rounded,
        emptyTitle: 'No conversations yet',
        emptySubtitle: "Messages from your child's teachers and the school office will appear here.",
        data: [
          StatsRow(items: [
            ('$unreadCount', 'Unread', null),
            ('$totalCount', 'Threads', null),
          ]),
          const SizedBox(height: EmSpacing.s12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Communication health', style: EmType.body.copyWith(color: EmColors.ink)),
                const SizedBox(height: EmSpacing.s4),
                Text('$readCount of $totalCount threads read', style: EmType.label.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
                const SizedBox(height: EmSpacing.s8),
                AppProgressBar(percent: healthPercent, color: EmColors.success),
              ],
            ),
          ),
          for (final t in threads) _ThreadRow(thread: t, onTap: () => _open(controller, t)),
        ],
      );
    });
  }

  Future<void> _open(MessagesController controller, dynamic t) async {
    await Get.toNamed(Routes.messageThread, arguments: {
      'threadId': t['_id']?.toString() ?? '',
      'subject': t['subject']?.toString() ?? 'Conversation',
      'staffName': t['staffName']?.toString() ?? 'Staff',
      'studentName': t['studentName']?.toString(),
    });
    // Opening a thread clears its unread flag server-side.
    controller.fetch();
  }
}

class _ThreadRow extends StatelessWidget {
  final dynamic thread;
  final VoidCallback onTap;
  const _ThreadRow({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = thread;
    final lastAt = t['lastMessageAt'] != null ? DateTime.tryParse(t['lastMessageAt'].toString()) : null;
    final unread = t['guardianHasUnread'] == true;
    final who = (t['staffName'] ?? 'Staff').toString();
    final preview = (t['lastMessagePreview'] ?? '').toString();
    final about = [
      if ((t['studentName'] ?? '').toString().isNotEmpty) 're ${t['studentName']}',
      if ((t['subject'] ?? '').toString().isNotEmpty) t['subject'].toString(),
    ].join(' · ');
    final when = lastAt == null ? null : '${lastAt.hour}:${lastAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.row),
      child: EmCard(
        key: Key('thread_${t['_id']}'),
        onTap: onTap,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.s16, vertical: EmSpacing.s12),
        semanticLabel: [who, if (about.isNotEmpty) about, if (unread) 'unread', if (when != null) when].join(', '),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EmAvatar(initials: _initials(who), size: 44),
          const SizedBox(width: EmSpacing.s12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(who, maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.body.copyWith(color: EmColors.ink, fontWeight: unread ? FontWeight.w700 : FontWeight.w600))),
                if (when != null) ...[
                  const SizedBox(width: EmSpacing.s8),
                  Text(when, maxLines: 1, softWrap: false, style: EmType.caption.copyWith(color: unread ? EmColors.primary : EmColors.textSecondary, fontWeight: unread ? FontWeight.w700 : FontWeight.w500)),
                ],
              ]),
              if (about.isNotEmpty) Text(about, maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.caption.copyWith(color: EmColors.textSecondary)),
              const SizedBox(height: EmSpacing.s4),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EmType.label.copyWith(color: unread ? EmColors.ink : EmColors.textSecondary, fontWeight: unread ? FontWeight.w600 : FontWeight.w400),
                  ),
                ),
                if (unread)
                  Container(
                    key: Key('unread_${t['_id']}'),
                    margin: const EdgeInsetsDirectional.only(start: EmSpacing.s8, top: EmSpacing.s4),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: EmColors.primary, shape: BoxShape.circle),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  /// First letters of the first and last word ("Mrs Malik" -> "M", "Sara Ahmed" -> "SA").
  static String _initials(String name) {
    final cleaned = name.replaceAll(RegExp(r'\([^)]*\)'), ' ').replaceAll(RegExp(r'^\s*(mr|mrs|ms|miss|dr)\.?\s+', caseSensitive: false), '');
    final parts = cleaned.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts.first[0];
    final b = parts.length > 1 ? parts.last[0] : '';
    return '$a$b'.toUpperCase();
  }
}
