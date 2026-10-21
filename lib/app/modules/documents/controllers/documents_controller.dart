import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

class DocumentsController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final documents = <dynamic>[].obs;
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
      documents.value = await _api.getAcademicDocuments(studentId);
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }
}
