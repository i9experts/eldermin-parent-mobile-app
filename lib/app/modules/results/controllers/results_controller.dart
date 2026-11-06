import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

class ResultsController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final reportCards = <dynamic>[].obs;
  final RxnString error = RxnString();
  final locked = false.obs;
  final RxnString downloadingId = RxnString();
  final RxnString selectedSubject = RxnString();

  String? _loadedForStudentId;

  @override
  void onInit() {
    super.onInit();
    ever(_students.selectedId, (_) => _loadIfStudentChanged());
    // The children list arrives over the network, usually after this controller
    // is created; selectedId stays null (first child is the default), so also
    // react to the list itself or the first load never happens.
    ever(_students.students, (_) => _loadIfStudentChanged());
    _loadIfStudentChanged();
  }

  void _loadIfStudentChanged() {
    final student = _students.selectedStudent;
    if (student == null || student.id == _loadedForStudentId) return;
    _loadedForStudentId = student.id;
    fetch();
  }

  Future<void> fetch() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    loading.value = true;
    error.value = null;
    locked.value = false;
    try {
      final result = await _api.getResults(studentId);
      if (result.suspended) {
        locked.value = true;
        reportCards.clear();
      } else {
        reportCards.value = result.data!;
      }
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }

  /// Chronological (oldest first) copy of the published report cards.
  List<dynamic> get chronological => reportCards.reversed.toList();

  /// Subjects that appear in at least two reports - the only ones with a trend to draw.
  List<String> get trendSubjects {
    final counts = <String, int>{};
    for (final rc in reportCards) {
      for (final s in (rc['subjects'] as List<dynamic>? ?? const [])) {
        final name = (s['subject'] ?? '').toString();
        if (name.isNotEmpty) counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    return counts.entries.where((e) => e.value >= 2).map((e) => e.key).toList();
  }

  /// Percentage per assessment for one subject, oldest first.
  List<(String, double)> subjectTrend(String subject) {
    final out = <(String, double)>[];
    for (final rc in chronological) {
      for (final s in (rc['subjects'] as List<dynamic>? ?? const [])) {
        if ((s['subject'] ?? '').toString() == subject && s['percentage'] is num) {
          out.add(((rc['assessmentTitle'] ?? rc['term'] ?? '').toString(), (s['percentage'] as num).toDouble()));
        }
      }
    }
    return out;
  }

  Future<void> openPdf(String reportCardId) async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null || downloadingId.value != null) return;
    downloadingId.value = reportCardId;
    try {
      final bytes = await _api.downloadResultPdf(studentId, reportCardId);
      // %PDF - anything else is the "feature suspended" JSON, not a document
      if (bytes.length < 4 || bytes[0] != 0x25 || bytes[1] != 0x50 || bytes[2] != 0x44 || bytes[3] != 0x46) {
        ToastUtil.showToast('This result PDF is not available right now.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/result-$reportCardId.pdf');
      await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) ToastUtil.showToast('Could not open the PDF.');
    } on ApiException catch (e) {
      ToastUtil.showToast(e.message);
    } finally {
      downloadingId.value = null;
    }
  }
}
