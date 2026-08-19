import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
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
          .where((h) => h['status'] != 'graded' && h['status'] != 'submitted')
          .toList();
    } else if (filter.value == 2) {
      base = items
          .where((h) => h['status'] == 'submitted' || h['status'] == 'graded')
          .toList();
    } else {
      base = items;
    }
    return base.where(_inSelectedMonth).toList();
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
    } catch (_) {
      error.value = 'Could not load homework';
    } finally {
      loading.value = false;
    }
  }
}
