import 'package:get/get.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/utils/greeting.dart' show uiNow;
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

/// Where a consent request stands for the selected student. Derived client-side: the backend has no status field.
enum ConsentStatus {
  /// No response yet and the due date (if any) has not passed: Grant / Decline are offered.
  pending,

  /// No response and the due date has passed: shown read-only.
  expired,

  /// Already answered: shown read-only, the answer cannot be changed from the app.
  responded,
}

class ConsentController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final requests = <dynamic>[].obs;
  final respondingId = RxnString();
  final RxnString error = RxnString();

  /// Why the last Grant / Decline failed. Kept apart from [error], which replaces the whole list with an error view.
  final RxnString respondError = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  /// Test seam: the first instant of the given calendar day in the device's local time zone.
  static DateTime Function(int year, int month, int day) startOfLocalDay = (y, m, d) => DateTime(y, m, d);

  /// The instant the due day is over: local midnight after the day the school picked. The web form sends a date-only value
  /// (`<input type="date">`, ConsentTab.tsx:33), the backend parses it as midnight UTC (`new Date('2026-11-15')`,
  /// parent-portal.service.ts:808) and returns `2026-11-15T00:00:00.000Z`. Its UTC calendar date is therefore the date that was picked, whatever
  /// the device's zone, and the request stays open until that day ends on the device's clock. Null when there is no due date.
  static DateTime? dueEnd(Map request) {
    final due = DateTime.tryParse(request['dueDate']?.toString() ?? '');
    if (due == null) return null;
    final d = due.toUtc();
    return startOfLocalDay(d.year, d.month, d.day + 1); // day + 1 rolls over month ends
  }

  static ConsentStatus statusOf(Map request, {DateTime? now}) {
    if (request['response'] is Map) return ConsentStatus.responded;
    final end = dueEnd(request);
    if (end != null && !(now ?? uiNow()).isBefore(end)) return ConsentStatus.expired;
    return ConsentStatus.pending;
  }

  static String idOf(Map request) => request['_id']?.toString() ?? request['id']?.toString() ?? '';

  /// The current copy of a request (the list is patched in place after a response).
  Map<String, dynamic>? byId(String id) {
    for (final raw in requests) {
      final r = Map<String, dynamic>.from(raw as Map);
      if (idOf(r) == id) return r;
    }
    return null;
  }

  Future<void> fetch() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    loading.value = true;
    error.value = null;
    try {
      requests.value = await _api.getConsentRequests(studentId);
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }

  /// Sends the answer for a pending request. Returns false (and sets [respondError]) when it could not be sent; a second call while one is
  /// in flight, or for a request that is not pending, is ignored.
  Future<bool> respond(String consentRequestId, String decision, {String? notes}) async {
    if (respondingId.value != null) return false;
    final studentId = _students.selectedStudent?.id;
    final item = byId(consentRequestId);
    if (studentId == null || item == null) {
      respondError.value = 'Could not find this request. Pull down to refresh and try again.';
      return false;
    }
    if (statusOf(item) != ConsentStatus.pending) {
      respondError.value = 'This request can no longer be answered.';
      return false;
    }
    respondingId.value = consentRequestId;
    respondError.value = null;
    try {
      final reason = notes?.trim();
      final saved = await _api.respondToConsent(studentId, consentRequestId, decision, notes: reason == null || reason.isEmpty ? null : reason);
      if (saved == null) {
        await fetch(); // the backend answered without the saved response: take its word for it instead of guessing
      } else {
        final i = requests.indexWhere((r) => idOf(Map.from(r as Map)) == consentRequestId);
        if (i >= 0) requests[i] = {...Map<String, dynamic>.from(requests[i] as Map), 'response': saved};
      }
      return true;
    } on ApiException catch (e) {
      respondError.value = e.message;
      return false;
    } finally {
      respondingId.value = null;
    }
  }
}
