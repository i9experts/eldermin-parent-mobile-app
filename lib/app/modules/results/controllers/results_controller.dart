import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

class ResultsController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final reportCards = <dynamic>[].obs;
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
      reportCards.value = await _api.getResults(studentId);
    } catch (_) {
      error.value = 'Could not load results';
    } finally {
      loading.value = false;
    }
  }
}
