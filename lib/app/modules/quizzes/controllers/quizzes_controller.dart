import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

/// Powers "My Quizzes" - every self-paced online quiz subject available
/// to this student (by grade/section) with their own attempt status, from
/// GET /parent-portal/students/:id/quizzes
/// (AssessmentService.listAvailableQuizzes on the backend).
class QuizzesController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final quizzes = <dynamic>[].obs;
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
      quizzes.value = await _api.getMyQuizzes(studentId);
    } catch (_) {
      error.value = 'Could not load quizzes';
    } finally {
      loading.value = false;
    }
  }
}
