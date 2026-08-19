import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

class LeavesController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final submitting = false.obs;
  final leaves = <dynamic>[].obs;
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
      leaves.value = await _api.getStudentLeaves(studentId);
    } catch (_) {
      error.value = 'Could not load leave requests';
    } finally {
      loading.value = false;
    }
  }

  Future<bool> submit(
      {required DateTime from,
      required DateTime to,
      required String reason,
      required String leaveType}) async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return false;
    submitting.value = true;
    try {
      await _api.createStudentLeave(
        studentId,
        fromDate: from.toIso8601String(),
        toDate: to.toIso8601String(),
        reason: reason,
        leaveType: leaveType,
      );
      await fetch();
      return true;
    } catch (_) {
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
