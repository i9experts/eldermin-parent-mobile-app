import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../students/controllers/student_controller.dart';

/// One sitting of a self-paced quiz: start (or resume) -> answer -> submit.
/// The server grades every auto-gradable question; subjective ones stay
/// "submitted" until the teacher marks them, so [result] may have no score yet.
class QuizAttemptController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  late final String assessmentId;
  late final String subject;
  late final String title;

  final loading = true.obs;
  final submitting = false.obs;
  final RxnString error = RxnString();
  final questions = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> attempt = Rxn();
  final Rxn<Map<String, dynamic>> result = Rxn();
  final currentIndex = 0.obs;

  /// questionId -> {selectedOptionIndex?, textAnswer?}
  final answers = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Map<String, dynamic>.from(Get.arguments as Map);
    assessmentId = args['assessmentId'] as String;
    subject = args['subject'] as String;
    title = args['title'] as String? ?? subject;
    start();
  }

  Future<void> start() async {
    final studentId = _students.selectedStudent?.id;
    if (studentId == null) return;
    loading.value = true;
    error.value = null;
    try {
      final res = await _api.startQuiz(studentId, assessmentId: assessmentId, subject: subject);
      attempt.value = Map<String, dynamic>.from(res['attempt'] as Map);
      questions.value = (res['questions'] as List<dynamic>).map((q) => Map<String, dynamic>.from(q as Map)).toList();
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  void selectOption(String questionId, int index) {
    answers[questionId] = {'questionId': questionId, 'selectedOptionIndex': index};
    answers.refresh();
  }

  void setText(String questionId, String text) {
    if (text.trim().isEmpty) {
      answers.remove(questionId);
    } else {
      answers[questionId] = {'questionId': questionId, 'textAnswer': text.trim()};
    }
    answers.refresh();
  }

  int get answeredCount => answers.length;

  void goTo(int i) => currentIndex.value = i.clamp(0, questions.length - 1);

  /// Returns an error message, or null on success.
  Future<String?> submit() async {
    final studentId = _students.selectedStudent?.id;
    final attemptId = attempt.value?['_id']?.toString();
    if (studentId == null || attemptId == null) return 'Quiz not started';
    submitting.value = true;
    try {
      result.value = await _api.submitQuiz(studentId, attemptId, answers.values.toList());
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      submitting.value = false;
    }
  }
}
