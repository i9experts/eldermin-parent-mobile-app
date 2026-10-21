import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

class CoursesController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final courses = <dynamic>[].obs;
  final RxnString error = RxnString();
  final RxnString updatingKey = RxnString();

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
      courses.value = await _api.getCourses(studentId);
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }

  static String lessonKey(String syllabusId, int unitNo, int topicNo, int lessonNo) =>
      '$syllabusId-$unitNo-$topicNo-$lessonNo';

  /// Marks a lesson with [status] (not_started | in_progress | completed),
  /// then refetches so the course's completion % comes from the server.
  Future<bool> setLessonStatus(String syllabusId, int unitNo, int topicNo, int lessonNo, String status) async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return false;
    updatingKey.value = lessonKey(syllabusId, unitNo, topicNo, lessonNo);
    try {
      await _api.markLessonProgress(studentId,
          syllabusId: syllabusId, unitNo: unitNo, topicNo: topicNo, lessonNo: lessonNo, status: status);
      await fetch();
      return true;
    } on ApiException catch (e) {
      ToastUtil.showToast(e.message);
      return false;
    } finally {
      updatingKey.value = null;
    }
  }
}
