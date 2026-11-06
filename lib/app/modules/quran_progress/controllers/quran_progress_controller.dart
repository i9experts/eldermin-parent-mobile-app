import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/models/nazra_models.dart';
import '../../../../core/models/qaida_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

/// The child's Qur'an journey: Qaida & Tajweed, then Nazra (`GET /parent-portal/students/:id/qaida` and `.../nazra`, loaded together).
/// A programme the child has not reached yet has no record ([qaida] / [nazra] null) and simply is not shown, so the screen grows with the
/// child: Qaida first, Nazra once the teacher starts recording it, and both stay available. Re-loads when the selected child changes.
class QuranProgressController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final RxnString error = RxnString();
  final locked = false.obs;
  final Rxn<QaidaReport> qaida = Rxn<QaidaReport>();
  final Rxn<NazraReport> nazra = Rxn<NazraReport>();
  final downloading = false.obs;

  /// Which programme tab is showing when both exist; null = the default (the latest stage the child has reached).
  final RxnInt picked = RxnInt();

  String? _loadedFor;
  int _token = 0;

  /// Nothing recorded in any programme yet.
  bool get isEmpty => qaida.value == null && nazra.value == null;

  /// 0 = Qaida, 1 = Nazra. Nazra (the later stage) is the default when the child has a record in both.
  int get segment {
    if (qaida.value == null) return 1;
    if (nazra.value == null) return 0;
    return picked.value ?? 1;
  }

  void pick(int i) => picked.value = i;

  @override
  void onInit() {
    super.onInit();
    ever(_students.selectedId, (_) => _onStudentChanged());
    ever(_students.students, (_) => _onStudentChanged());
    fetch();
  }

  void _onStudentChanged() {
    final id = _students.selectedStudent?.id;
    if (id == null || id == _loadedFor) return;
    qaida.value = null;
    nazra.value = null;
    picked.value = null;
    fetch();
  }

  Future<void> fetch() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    final token = ++_token;
    loading.value = true;
    error.value = null;
    locked.value = false;
    try {
      final results = await Future.wait([_api.getQaidaReport(studentId), _api.getNazraReport(studentId)]);
      if (token != _token) return;
      _loadedFor = studentId;
      if (results.any((r) => r.suspended)) {
        locked.value = true;
        qaida.value = null;
        nazra.value = null;
      } else {
        qaida.value = QaidaReport.fromResponse(results[0].data!);
        nazra.value = NazraReport.fromResponse(results[1].data!);
      }
    } on ApiException catch (e) {
      if (token != _token) return;
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } catch (_) {
      // an unexpected payload must end in the error view, never in a stuck spinner
      if (token != _token) return;
      error.value = 'Something went wrong. Please try again.';
    } finally {
      if (token == _token) loading.value = false;
    }
  }

  /// The Qaida report as the school's PDF (the web tracker has no Nazra PDF).
  Future<void> openQaidaPdf() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null || downloading.value) return;
    downloading.value = true;
    try {
      final bytes = await _api.downloadQaidaPdf(studentId);
      // %PDF - anything else is the "feature suspended" JSON, not a document
      if (bytes.length < 4 || bytes[0] != 0x25 || bytes[1] != 0x50 || bytes[2] != 0x44 || bytes[3] != 0x46) {
        ToastUtil.showToast('This report is not available right now.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qaida-report-$studentId.pdf');
      await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) ToastUtil.showToast('Could not open the PDF.');
    } on ApiException catch (e) {
      ToastUtil.showToast(e.message);
    } finally {
      downloading.value = false;
    }
  }
}
