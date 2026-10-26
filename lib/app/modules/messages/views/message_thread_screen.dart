import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/message_thread_controller.dart';

class MessageThreadScreen extends GetView<MessageThreadController> {
  const MessageThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: controller.staffName,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            if (controller.studentName != null)
              CustomText(
                text: 'Re: ${controller.studentName}',
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
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
                    padding: const EdgeInsets.all(AppSpacing.md),
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isGuardian = m['senderRole'] == 'guardian';
                    final createdAt = m['createdAt'] != null
                        ? DateTime.tryParse(m['createdAt'].toString())
                        : null;
                    return Align(
                      alignment: isGuardian
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isGuardian
                              ? AppColors.primaryColor
                              : AppColors.background,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isGuardian ? 14 : 2),
                            bottomRight: Radius.circular(isGuardian ? 2 : 14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText(
                              text: (m['body'] ?? '').toString(),
                              color: isGuardian ? Colors.white : AppColors.ink,
                              fontSize: 13,
                            ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 4),
                              CustomText(
                                text:
                                    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                                color: isGuardian
                                    ? Colors.white.withOpacity(0.7)
                                    : AppColors.faint,
                                fontSize: 9,
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.replyController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => Material(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap:
                              controller.sending.value ? null : controller.send,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: controller.sending.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 18),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
