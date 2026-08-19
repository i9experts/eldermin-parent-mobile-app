import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';

class MessagesController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();

  final loading = false.obs;
  final threads = <dynamic>[].obs;
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
      threads.value = await _api.getThreads();
    } catch (_) {
      error.value = 'Could not load messages';
    } finally {
      loading.value = false;
    }
  }
}
