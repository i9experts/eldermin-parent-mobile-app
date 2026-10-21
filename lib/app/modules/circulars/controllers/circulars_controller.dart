import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';

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
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }

  Future<void> acknowledge(String id) async {
    try {
      await _api.acknowledgeCircular(id);
      await fetch();
    } on ApiException catch (e) {
      ToastUtil.showToast(e.message);
    }
  }
}
