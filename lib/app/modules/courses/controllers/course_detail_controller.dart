import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../students/controllers/student_controller.dart';
import 'courses_controller.dart';

/// One course's lesson tree + per-lesson progress marking. Receives its
/// starting data via Get.arguments (the course map CoursesScreen already
/// has) rather than re-fetching - same arguments-passing convention
/// OtpVerifyController uses - so opening a course from the list is
/// instant, not a second loading spinner for data already in memory.
class CourseDetailController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  late Map<String, dynamic> course;
  // Bumped on every local mutation to force Obx rebuilds - `course` itself
  // is a plain Map (not an Rx type) since it's mutated in place field by
  // field rather than replaced wholesale.
  final version = 0.obs;
  // "unitNo-topicNo-lessonNo" of the row currently saving, so only that
  // row shows a spinner instead of blocking the whole screen.
  final RxnString savingKey = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    course = Map<String, dynamic>.from(args['course'] as Map? ?? {});
  }

  String _keyFor(int unitNo, int topicNo, int lessonNo) => '$unitNo-$topicNo-$lessonNo';

  Future<void> setLessonStatus(int unitNo, int topicNo, int lessonNo, String status) async {
    final studentId = _students.selectedStudent?.id;
    final syllabusId = course['syllabusId']?.toString();
    if (studentId == null || syllabusId == null) return;

    final key = _keyFor(unitNo, topicNo, lessonNo);
    savingKey.value = key;
    try {
      await _api.markLessonProgress(
        studentId,
        syllabusId: syllabusId,
        unitNo: unitNo,
        topicNo: topicNo,
        lessonNo: lessonNo,
        status: status,
      );
      _applyLocalStatus(unitNo, topicNo, lessonNo, status);
      if (Get.isRegistered<CoursesController>()) {
        Get.find<CoursesController>().updateCourseLocally(course);
      }
    } catch (_) {
      CustomAppSnackbar.error('Could not update lesson status. Please try again.');
    } finally {
      savingKey.value = null;
    }
  }

  void _applyLocalStatus(int unitNo, int topicNo, int lessonNo, String status) {
    final units = (course['units'] as List?) ?? [];
    for (final u in units) {
      final unitMap = Map<String, dynamic>.from(u as Map);
      if (unitMap['unitNo'] != unitNo) continue;
      final topics = (unitMap['topics'] as List?) ?? [];
      for (final t in topics) {
        final topicMap = Map<String, dynamic>.from(t as Map);
        if (topicMap['topicNo'] != topicNo) continue;
        final lessons = (topicMap['lessons'] as List?) ?? [];
        for (final l in lessons) {
          final lessonMap = l as Map;
          if (lessonMap['lessonNo'] == lessonNo) lessonMap['status'] = status;
        }
      }
    }

    int total = 0;
    int completed = 0;
    for (final u in units) {
      for (final t in (Map<String, dynamic>.from(u as Map)['topics'] as List? ?? [])) {
        for (final l in (Map<String, dynamic>.from(t as Map)['lessons'] as List? ?? [])) {
          total += 1;
          if ((l as Map)['status'] == 'completed') completed += 1;
        }
      }
    }
    course['totalLessons'] = total;
    course['completedLessons'] = completed;
    course['completionPct'] = total > 0 ? ((completed / total) * 100).round() : 0;
    version.value++;
  }
}
