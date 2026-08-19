import 'package:get/get.dart';
import '../../../../core/models/student.dart';
import '../../../../core/services/parent_api_service.dart';

/// The list of children linked to this account, plus which one is
/// currently selected - every per-student screen reads [selectedStudent]
/// rather than each screen re-fetching or guessing which child is
/// "current". Registered once (permanent) in InitialBinding.
class StudentController extends GetxController {
  final ParentApiService _api;
  StudentController(this._api);

  final students = <Student>[].obs;
  final loading = false.obs;
  final RxnString error = RxnString();
  final RxnString selectedId = RxnString();

  Student? get selectedStudent {
    if (students.isEmpty) return null;
    final id = selectedId.value;
    if (id == null) return students.first;
    return students.firstWhereOrNull((s) => s.id == id) ?? students.first;
  }

  Future<void> fetchMyStudents() async {
    loading.value = true;
    error.value = null;
    try {
      final raw = await _api.getMyStudents();
      students.value = raw
          .map((e) => Student.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      error.value = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      loading.value = false;
    }
  }

  void selectStudent(String id) => selectedId.value = id;

  void reset() {
    students.clear();
    selectedId.value = null;
    error.value = null;
  }
}
