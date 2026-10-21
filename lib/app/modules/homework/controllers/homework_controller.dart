import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

class HomeworkController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final items = <dynamic>[].obs;
  final RxnString error = RxnString();
  final filter = 0.obs;
  final selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month).obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  bool _inSelectedMonth(dynamic h) {
    final raw = h['dueDate'];
    if (raw == null) return true;
    final due = DateTime.tryParse(raw.toString());
    if (due == null) return true;
    return due.year == selectedMonth.value.year &&
        due.month == selectedMonth.value.month;
  }

  List<dynamic> get filtered {
    List<dynamic> base;
    if (filter.value == 1) {
      base = items
          .where((h) => !['submitted', 'late', 'graded'].contains((h['mySubmission'] is Map ? h['mySubmission']['status'] : null)))
          .toList();
    } else if (filter.value == 2) {
      base = items
          .where((h) => ['submitted', 'late', 'graded'].contains((h['mySubmission'] is Map ? h['mySubmission']['status'] : null)))
          .toList();
    } else {
      base = items;
    }
    return base.where(_inSelectedMonth).toList();
  }

  final submittingId = RxnString();

  Future<String?> submit(String assignmentId, String text) async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return 'No child selected';
    submittingId.value = assignmentId;
    try {
      await _api.submitHomework(studentId, assignmentId, textResponse: text);
      await fetch();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not submit. Please try again.';
    } finally {
      submittingId.value = null;
    }
  }

  void changeFilter(int index) => filter.value = index;

  void changeMonth(DateTime month) => selectedMonth.value = month;

  Future<void> fetch() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    loading.value = true;
    error.value = null;
    try {
      items.value = await _api.getHomework(studentId);
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }
}
