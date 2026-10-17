import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

/// Powers "My Courses" - the published Syllabus lessons + this student's
/// own completion state, from GET /parent-portal/students/:id/courses
/// (ParentPortalService.getMyCourses on the backend). Course items are
/// kept as plain maps (same convention as every other module here -
/// Homework, Results, Dues - none of them have a typed model either).
class CoursesController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final courses = <dynamic>[].obs;
  final RxnString error = RxnString();

  String? _loadedForStudentId;

  @override
  void onInit() {
    super.onInit();
    ever(_students.selectedId, (_) => _loadIfStudentChanged());
    _loadIfStudentChanged();
  }

  void _loadIfStudentChanged() {
    final student = _students.selectedStudent;
    if (student == null || student.id == _loadedForStudentId) return;
    _loadedForStudentId = student.id;
    fetch();
  }

  Future<void> fetch() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    loading.value = true;
    error.value = null;
    try {
      courses.value = await _api.getMyCourses(studentId);
    } catch (_) {
      error.value = 'Could not load courses';
    } finally {
      loading.value = false;
    }
  }

  /// Called by CourseDetailController after a lesson's progress changes,
  /// so the list screen reflects the new completion % without a second
  /// network round trip when the student navigates back.
  void updateCourseLocally(Map<String, dynamic> updated) {
    final idx = courses.indexWhere(
        (c) => c['syllabusId']?.toString() == updated['syllabusId']?.toString());
    if (idx != -1) courses[idx] = updated;
  }
}
