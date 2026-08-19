import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';

class EventsController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();

  final loading = false.obs;
  final events = <dynamic>[].obs;
  final RxnString error = RxnString();

  /// The month the events calendar's month picker is currently focused on.
  /// Filtering happens client-side over the already-fetched [events],
  /// matched against each event's real `startDate` field.
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;

  void changeMonth(DateTime month) =>
      selectedMonth.value = DateTime(month.year, month.month);

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      events.value = await _api.getEvents();
    } catch (_) {
      error.value = 'Could not load events';
    } finally {
      loading.value = false;
    }
  }
}
