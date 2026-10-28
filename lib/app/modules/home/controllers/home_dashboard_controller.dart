import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

/// Backs the home tab's attendance/homework/dues summary - re-fetched
/// whenever the selected child changes, mirroring the old
/// FutureProvider.autoDispose trio keyed off selectedStudentProvider.
class HomeDashboardController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  // Start as loading so the first frame shows shimmer, not an empty state, before the first fetch begins.
  final attendanceLoading = true.obs;
  final attendance = <dynamic>[].obs;
  final RxnString attendanceError = RxnString();

  final homeworkLoading = true.obs;
  final homework = <dynamic>[].obs;
  final RxnString homeworkError = RxnString();

  final duesLoading = true.obs;
  final dues = <dynamic>[].obs;

  final eventsLoading = false.obs;
  final events = <dynamic>[].obs;

  String? _loadedForStudentId;

  @override
  void onInit() {
    super.onInit();
    ever(_students.selectedId, (_) => _loadIfStudentChanged());
    // The children list arrives over the network, usually after this controller
    // is created; selectedId stays null (first child is the default), so also
    // react to the list itself or the first load never happens.
    ever(_students.students, (_) => _loadIfStudentChanged());
    _loadIfStudentChanged();
  }

  void _loadIfStudentChanged() {
    final student = _students.selectedStudent;
    if (student == null || student.id == _loadedForStudentId) return;
    _loadedForStudentId = student.id;
    refresh(student.id);
  }

  @override
  Future<void> refresh([String? studentId]) async {
    final id = studentId ?? _students.selectedStudent?.id;
    if (id == null) return;

    attendanceLoading.value = true;
    attendanceError.value = null;
    homeworkLoading.value = true;
    homeworkError.value = null;
    duesLoading.value = true;
    eventsLoading.value = true;

    await Future.wait([
      _fetchAttendance(id),
      _fetchHomework(id),
      _fetchDues(id),
      _fetchEvents(),
    ]);
  }

  Future<void> _fetchAttendance(String id) async {
    try {
      attendance.value = await _api.getAttendance(id);
    } catch (_) {
      attendanceError.value = 'Could not load attendance';
    } finally {
      attendanceLoading.value = false;
    }
  }

  Future<void> _fetchHomework(String id) async {
    try {
      homework.value = await _api.getHomework(id);
    } catch (_) {
      homeworkError.value = 'Could not load homework';
    } finally {
      homeworkLoading.value = false;
    }
  }

  Future<void> _fetchDues(String id) async {
    try {
      dues.value = await _api.getDues(id);
    } catch (_) {
      // Dues failure is silent on the dashboard summary card - the
      // dedicated Dues screen still surfaces the error on its own.
    } finally {
      duesLoading.value = false;
    }
  }

  Future<void> _fetchEvents() async {
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day).toIso8601String();
      events.value = await _api.getEvents(from: from);
    } catch (_) {
      // Non-critical for the dashboard summary - the dedicated Events
      // screen still surfaces its own error state.
    } finally {
      eventsLoading.value = false;
    }
  }
}
