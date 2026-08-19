import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

class LearningResourcesController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final plans = <dynamic>[].obs;
  final RxnString error = RxnString();

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
      plans.value = await _api.getLearningResources(studentId);
    } catch (_) {
      error.value = 'Could not load learning resources';
    } finally {
      loading.value = false;
    }
  }
}
