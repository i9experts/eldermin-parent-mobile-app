import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';

class CircularsController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();

  final loading = false.obs;
  final circulars = <dynamic>[].obs;
  final RxnString error = RxnString();

  /// The month the circulars screen's month picker is currently focused on.
  /// Filtering happens client-side over the already-fetched [circulars],
  /// matched against each circular's real `effectiveDate` (falling back to
  /// `createdAt`) field.
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
      circulars.value = await _api.getCirculars();
    } catch (_) {
      error.value = 'Could not load school updates';
    } finally {
      loading.value = false;
    }
  }
}
