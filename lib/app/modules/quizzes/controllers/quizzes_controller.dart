import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

class QuizzesController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final quizzes = <dynamic>[].obs;
  final RxnString error = RxnString();
  final locked = false.obs;

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
    locked.value = false;
    try {
      final result = await _api.getQuizzes(studentId);
      if (result.suspended) {
        locked.value = true;
        quizzes.clear();
      } else {
        quizzes.value = result.data!;
      }
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }
}
