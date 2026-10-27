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

  /// The circular being acknowledged, null when none is in flight.
  final acknowledgingId = RxnString();

  /// Why the last acknowledgement failed (shown in the detail sheet).
  final RxnString acknowledgeError = RxnString();

  /// Current copy of a circular (patched in place after an acknowledgement).
  Map<String, dynamic>? byId(String id) {
    for (final raw in circulars) {
      final c = Map<String, dynamic>.from(raw as Map);
      if (c['_id']?.toString() == id) return c;
    }
    return null;
  }

  /// Acknowledges a circular. Returns false (and sets [acknowledgeError]) on failure; ignored while another acknowledgement is in flight.
  Future<bool> acknowledge(String id) async {
    if (acknowledgingId.value != null) return false;
    acknowledgingId.value = id;
    acknowledgeError.value = null;
    try {
      await _api.acknowledgeCircular(id);
      final i = circulars.indexWhere((r) => (r as Map)['_id']?.toString() == id);
      if (i >= 0) circulars[i] = {...Map<String, dynamic>.from(circulars[i] as Map), 'acknowledged': true};
      return true;
    } on ApiException catch (e) {
      acknowledgeError.value = e.message;
      return false;
    } finally {
      acknowledgingId.value = null;
    }
  }
}
