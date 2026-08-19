import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

class TarbiyahController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final behaviourRecords = <dynamic>[].obs;
  final tarbiyahAssessments = <dynamic>[].obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Map<String, dynamic>? get latestAssessment {
    if (tarbiyahAssessments.isEmpty) return null;
    final sorted = [...tarbiyahAssessments]..sort((a, b) {
        final da = DateTime.tryParse(a['assessmentDate']?.toString() ?? '') ??
            DateTime(2000);
        final db = DateTime.tryParse(b['assessmentDate']?.toString() ?? '') ??
            DateTime(2000);
        return db.compareTo(da);
      });
    return Map<String, dynamic>.from(sorted.first as Map);
  }

  Future<void> fetch() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    loading.value = true;
    error.value = null;
    try {
      final data = await _api.getBehaviourAndTarbiyah(studentId);
      behaviourRecords.value = data['behaviourRecords'] as List<dynamic>? ?? [];
      tarbiyahAssessments.value =
          data['tarbiyahAssessments'] as List<dynamic>? ?? [];
    } catch (_) {
      error.value = 'Could not load growth & tarbiyah records';
    } finally {
      loading.value = false;
    }
  }
}
