import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

class ProfileController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final profile = Rxn<Map<String, dynamic>>();
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
      profile.value = await _api.getStudentProfile(studentId);
    } catch (_) {
      error.value = 'Could not load student profile';
    } finally {
      loading.value = false;
    }
  }
}
