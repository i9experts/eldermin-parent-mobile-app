import 'package:get/get.dart';
import '../../../../core/models/behaviour_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../utils/toast_util.dart';
import '../../students/controllers/student_controller.dart';

/// Behaviour & Tarbiyah of the selected child (`GET /parent-portal/students/:id/behaviour`, one call: records + shared assessments).
///
/// The endpoint cannot page: it returns the latest [kParentRecordsServerLimit] records and [kParentAssessmentsServerLimit] shared
/// assessments, so [recordsMayBeTruncated] / [assessmentsMayBeTruncated] tell the screen to say that older ones exist instead of dropping
/// them silently. Filters run on the loaded list. Re-loads when the selected child changes.
class TarbiyahController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  final loading = false.obs;
  final RxnString error = RxnString();
  final locked = false.obs;

  final records = <ParentBehaviourRecord>[].obs;
  final assessments = <TarbiyahReport>[].obs;
  final filter = Rx<RecordFilter>(RecordFilter.none);

  String? _loadedFor;
  int _token = 0;

  @override
  void onInit() {
    super.onInit();
    ever(_students.selectedId, (_) => _onStudentChanged());
    fetch();
  }

  void _onStudentChanged() {
    final id = _students.selectedStudent?.id;
    if (id == null || id == _loadedFor) return;
    records.clear();
    assessments.clear();
    filter.value = RecordFilter.none;
    fetch();
  }

  /// The newest shared assessment (the headline), null when none.
  TarbiyahReport? get latestAssessment => assessments.isEmpty ? null : assessments.first;

  /// Records after the filter, newest first.
  List<ParentBehaviourRecord> get visibleRecords => [for (final r in records) if (filter.value.accepts(r)) r];

  int get meritCount => records.where((r) => r.kind == BehaviourKind.merit).length;
  int get concernCount => records.where((r) => r.kind == BehaviourKind.concern).length;

  bool get recordsMayBeTruncated => records.length >= kParentRecordsServerLimit;
  bool get assessmentsMayBeTruncated => assessments.length >= kParentAssessmentsServerLimit;

  /// Nothing to show at all (no records, no assessments).
  bool get isEmpty => records.isEmpty && assessments.isEmpty;

  void setFilter(RecordFilter f) => filter.value = f;

  Future<void> fetch() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    final token = ++_token;
    loading.value = true;
    error.value = null;
    locked.value = false;
    try {
      final result = await _api.getBehaviourAndTarbiyah(studentId);
      if (token != _token) return;
      _loadedFor = studentId;
      if (result.suspended) {
        locked.value = true;
        records.clear();
        assessments.clear();
      } else {
        final parsed = BehaviourAndTarbiyah.fromJson(result.data);
        records.assignAll(parsed.records);
        assessments.assignAll(parsed.assessments);
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
}
