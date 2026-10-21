import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

class PtmController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final meetings = <dynamic>[].obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    loading.value = true;
    error.value = null;
    try {
      meetings.value = await _api.getPTMHistory(studentId);
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }

  final submitting = false.obs;
  final teachers = <dynamic>[].obs;

  Future<void> loadTeachers() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    try {
      teachers.value = await _api.getPTMTeachers(studentId);
    } on ApiException catch (e) {
      ToastUtil.showToast(e.message);
    }
  }

  /// Returns null on success, otherwise the server's error message.
  Future<String?> request({required String teacherId, required DateTime date, String? time, String? reason}) async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return 'No child selected.';
    submitting.value = true;
    try {
      await _api.requestPTM(studentId,
          teacherId: teacherId, scheduledDate: date.toIso8601String(), startTime: time, reason: reason);
      await fetch();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      submitting.value = false;
    }
  }

  Future<String?> cancel(String meetingId) async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return 'No child selected.';
    try {
      await _api.cancelPTM(studentId, meetingId);
      await fetch();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
