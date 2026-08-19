import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

class LibraryController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final issues = <dynamic>[].obs;
  final RxnString error = RxnString();

  /// The month the library screen's month picker is currently focused on.
  /// Filtering happens client-side over the already-fetched [issues] (the
  /// library API has no date-range param), matched against each issue's
  /// real `dueDate`/`returnDate`/`issueDate` fields.
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;

  void changeMonth(DateTime month) =>
      selectedMonth.value = DateTime(month.year, month.month);

  /// Issues whose due date, return date, or issue date falls in
  /// [selectedMonth]. An issue with none of those dates present is always
  /// shown (there's nothing dated to exclude it by).
  List<dynamic> get issuesForSelectedMonth {
    bool inMonth(dynamic v) {
      final d = v != null ? DateTime.tryParse(v.toString()) : null;
      return d != null &&
          d.year == selectedMonth.value.year &&
          d.month == selectedMonth.value.month;
    }

    return issues.where((raw) {
      final b = raw as Map;
      final hasAnyDate =
          b['dueDate'] != null || b['returnDate'] != null || b['issueDate'] != null;
      if (!hasAnyDate) return true;
      return inMonth(b['dueDate']) ||
          inMonth(b['returnDate']) ||
          inMonth(b['issueDate']);
    }).toList();
  }

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
      issues.value = await _api.getLibrary(studentId);
    } catch (_) {
      error.value = 'Could not load library records';
    } finally {
      loading.value = false;
    }
  }
}
