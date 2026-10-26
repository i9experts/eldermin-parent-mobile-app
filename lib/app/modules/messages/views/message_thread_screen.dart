import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../controllers/message_thread_controller.dart';

class MessageThreadScreen extends GetView<MessageThreadController> {
  const MessageThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(
        titleWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(controller.staffName, maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.heading.copyWith(color: EmColors.ink)),
            if (controller.studentName != null)
              Text('Re: ${controller.studentName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.caption.copyWith(color: EmColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.loading.value && controller.messages.isEmpty) {
                return AppShimmer(
                  child: ListView(
                    padding: EmSpacing.listPadding,
                    children: shimmerListRows(6),
                  ),
                );
              }
              if (controller.error.value != null &&
                  controller.messages.isEmpty) {
                return AppErrorView(
                    message: controller.error.value!,
                    onRetry: controller.fetch);
              }
              final messages = controller.messages;
              if (messages.isEmpty) {
                return const AppEmptyView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No messages yet',
                    subtitle: 'Send the first message below.');
              }
              return RefreshIndicator(
                onRefresh: controller.fetch,
                child: ListView.builder(
                  padding: EmSpacing.listPadding,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isGuardian = m['senderRole'] == 'guardian';
                    final createdAt = m['createdAt'] != null
                        ? DateTime.tryParse(m['createdAt'].toString())
                        : null;
                    return Align(
                      alignment: isGuardian ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.s16, vertical: EmSpacing.s12),
                        decoration: BoxDecoration(
                          color: isGuardian ? EmColors.primary : EmColors.surface,
                          border: Border.all(color: isGuardian ? EmColors.primary : EmColors.border),
                          borderRadius: BorderRadiusDirectional.only(
                            topStart: const Radius.circular(EmRadius.md),
                            topEnd: const Radius.circular(EmRadius.md),
                            bottomStart: Radius.circular(isGuardian ? EmRadius.md : EmSpacing.s4),
                            bottomEnd: Radius.circular(isGuardian ? EmSpacing.s4 : EmRadius.md),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text((m['body'] ?? '').toString(), style: EmType.body.copyWith(color: isGuardian ? EmColors.onPrimary : EmColors.ink, fontWeight: FontWeight.w400)),
                            if (createdAt != null) ...[
                              const SizedBox(height: EmSpacing.s4),
                              Text(
                                '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                                style: EmType.caption.copyWith(color: isGuardian ? EmColors.onPrimary : EmColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          // composer (teacher thread pattern, `message_thread_screen.dart:231-270`)
          DecoratedBox(
            decoration: const BoxDecoration(color: EmColors.surface, border: Border(top: BorderSide(color: EmColors.border))),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.s16, EmSpacing.s8, EmSpacing.s16, EmSpacing.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.replyController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: EmType.body.copyWith(color: EmColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Type a message…',
                          hintStyle: EmType.body.copyWith(color: EmColors.textTertiary),
                          filled: true,
                          fillColor: EmColors.background,
                          contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.s16, vertical: EmSpacing.s12),
                          border: const OutlineInputBorder(borderRadius: EmRadius.tileAll, borderSide: BorderSide.none),
                          enabledBorder: const OutlineInputBorder(borderRadius: EmRadius.tileAll, borderSide: BorderSide.none),
                          focusedBorder: const OutlineInputBorder(borderRadius: EmRadius.tileAll, borderSide: BorderSide(color: EmColors.primary, width: 2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: EmSpacing.s8),
                    Obx(() => IconButton(
                          key: const Key('send_message'),
                          tooltip: 'Send',
                          onPressed: controller.sending.value ? null : controller.send,
                          style: IconButton.styleFrom(
                            backgroundColor: EmColors.primary,
                            disabledBackgroundColor: EmColors.disabled,
                            minimumSize: const Size(EmSpacing.minTouch, EmSpacing.minTouch),
                          ),
                          icon: controller.sending.value
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: EmColors.onPrimary))
                              : const Icon(Icons.send_rounded, color: EmColors.onPrimary, size: 20),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
