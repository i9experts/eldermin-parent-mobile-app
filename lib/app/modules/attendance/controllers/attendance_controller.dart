import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

class AttendanceController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final records = <dynamic>[].obs;
  final RxnString error = RxnString();

  /// The month the attendance screen's month picker is currently focused
  /// on. Filtering happens client-side over the already-fetched [records]
  /// (fetch() stays unbounded), matched against each record's real `date`
  /// field.
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;

  void changeMonth(DateTime month) =>
      selectedMonth.value = DateTime(month.year, month.month);

  /// Records whose `date` falls in [selectedMonth].
  List<dynamic> get recordsForSelectedMonth {
    return records.where((r) {
      final d = r['date'] != null ? DateTime.tryParse(r['date'].toString()) : null;
      return d != null &&
          d.year == selectedMonth.value.year &&
          d.month == selectedMonth.value.month;
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
      records.value = await _api.getAttendance(studentId);
    } catch (_) {
      error.value = 'Could not load attendance';
    } finally {
      loading.value = false;
    }
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Percentage of days present, grouped by calendar month, for the last
  /// (up to) 6 distinct months that actually have attendance records -
  /// backs the "6-month trend" bar chart with real data only.
  List<(String, double)> get monthlyAttendancePercent {
    final byMonth = <String, List<dynamic>>{};
    for (final r in records) {
      final d = r['date'] != null ? DateTime.tryParse(r['date'].toString()) : null;
      if (d == null) continue;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(r);
    }
    final sortedKeys = byMonth.keys.toList()..sort();
    final last6 = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;
    return last6.map((key) {
      final list = byMonth[key]!;
      final present = list.where((r) => r['status'] == 'present').length;
      final pct = list.isEmpty ? 0.0 : (present / list.length) * 100;
      final month = int.parse(key.split('-')[1]);
      return (_monthNames[month - 1], pct);
    }).toList();
  }
}
