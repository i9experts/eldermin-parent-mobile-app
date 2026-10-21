import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

class TimetableController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final Rxn<Map<String, dynamic>> timetable = Rxn<Map<String, dynamic>>();
  final RxnString error = RxnString();
  final selectedDay = (DateTime.now().weekday - 1).obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void changeDay(int day) => selectedDay.value = day;

  Future<void> fetch() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    loading.value = true;
    error.value = null;
    try {
      timetable.value = await _api.getTimetable(studentId);
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }
}
