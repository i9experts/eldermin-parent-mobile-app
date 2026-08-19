import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';

class NotificationsController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();

  final loading = false.obs;
  final items = <dynamic>[].obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      items.value = await _api.getNotifications();
    } catch (_) {
      error.value = 'Could not load notifications';
    } finally {
      loading.value = false;
    }
  }

  Future<bool> markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.markNotificationRead(id);
      await fetch();
    } catch (_) {
      // Best-effort - opening the notification is the primary action here;
      // a failed read-receipt isn't worth interrupting the user for, and
      // it'll naturally retry next time this screen fetches.
    }
  }
}
