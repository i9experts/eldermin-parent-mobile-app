import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

class DiaryController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final entries = <dynamic>[].obs;
  final RxnString error = RxnString();
  final RxnString downloadingId = RxnString();
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
      final result = await _api.getClassDiary(studentId);
      if (result.suspended) {
        locked.value = true;
        entries.clear();
      } else {
        entries.value = result.data!;
      }
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }

  Future<void> openPdf(String diaryId) async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null || downloadingId.value != null) return;
    downloadingId.value = diaryId;
    try {
      final bytes = await _api.downloadClassDiaryPdf(studentId, diaryId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/class-diary-$diaryId.pdf');
      await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        ToastUtil.showToast('Could not open the PDF.');
      }
    } on ApiException catch (e) {
      ToastUtil.showToast(e.message);
    } finally {
      downloadingId.value = null;
    }
  }
}
