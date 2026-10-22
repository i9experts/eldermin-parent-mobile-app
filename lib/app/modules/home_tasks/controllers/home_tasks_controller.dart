import 'package:get/get.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

class HomeTasksController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final completingId = RxnString();
  final tasks = <dynamic>[].obs;
  final RxnString error = RxnString();
  final locked = false.obs;
  String? lastError;

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
    locked.value = false;
    try {
      final result = await _api.getHomeTasks(studentId);
      if (result.suspended) {
        locked.value = true;
        tasks.clear();
        return;
      }
      final list = result.data!;
      // To-do first (soonest due date on top), completed after.
      int rank(dynamic t) => t['status'] == 'completed' ? 1 : 0;
      DateTime? due(dynamic t) => DateTime.tryParse(t['dueDate']?.toString() ?? '');
      list.sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        final da = due(a), db = due(b);
        if (da == null || db == null) return da == null ? (db == null ? 0 : 1) : -1;
        return rank(a) == 0 ? da.compareTo(db) : db.compareTo(da);
      });
      tasks.value = list;
    } on ApiException catch (e) {
      error.value = e.message;
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
      final result = await _api.completeHomeTask(studentId, taskId, parentNotes: parentNotes);
      if (result.suspended) {
        locked.value = true;
        lastError = null;
        return false;
      }
      await fetch();
      return true;
    } on ApiException catch (e) {
      lastError = e.message;
      return false;
    } catch (_) {
      lastError = null;
      return false;
    } finally {
      completingId.value = null;
    }
  }
}
