import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../utils/toast_util.dart';

class MessageThreadController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();

  late final String threadId;
  late final String subject;
  late final String staffName;
  late final String? studentName;

  final replyController = TextEditingController();
  final loading = false.obs;
  final sending = false.obs;
  final messages = <dynamic>[].obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    threadId = args['threadId'] as String? ?? '';
    subject = args['subject'] as String? ?? 'Conversation';
    staffName = args['staffName'] as String? ?? 'Staff';
    studentName = args['studentName'] as String?;
    fetch();
  }

  @override
  void onClose() {
    replyController.dispose();
    super.onClose();
  }

  Future<void> fetch() async {
    if (threadId.isEmpty) return;
    loading.value = true;
    error.value = null;
    try {
      messages.value = await _api.getThreadMessages(threadId);
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }

  Future<void> send() async {
    final body = replyController.text.trim();
    if (body.isEmpty || threadId.isEmpty) return;
    sending.value = true;
    try {
      await _api.sendMessage(threadId, body);
      replyController.clear();
      await fetch();
    } on ApiException catch (e) {
      ToastUtil.showToast(e.message);
    } finally {
      sending.value = false;
    }
  }
}
