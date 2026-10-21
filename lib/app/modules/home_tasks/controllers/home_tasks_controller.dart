import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

class HomeTasksController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final completingId = RxnString();
  final tasks = <dynamic>[].obs;
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
      tasks.value = await _api.getHomeTasks(studentId);
    } catch (_) {
      error.value = 'Could not load home tasks';
    } finally {
      loading.value = false;
    }
  }

  Future<bool> complete(String taskId, {String? parentNotes}) async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return false;
    completingId.value = taskId;
    try {
      await _api.completeHomeTask(studentId, taskId, parentNotes: parentNotes);
      await fetch();
      return true;
    } catch (_) {
      return false;
    } finally {
      completingId.value = null;
    }
  }
}
