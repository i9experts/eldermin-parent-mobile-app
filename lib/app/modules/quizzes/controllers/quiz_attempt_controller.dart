import 'package:get/get.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';
import 'quizzes_controller.dart';

/// One in-progress (or resumed) quiz attempt: loads sanitized questions
/// (no answer keys - stripped server-side), tracks the student's answers
/// locally, and submits for grading. Receives assessmentId/subject via
/// Get.arguments, same convention as OtpVerifyController.
class QuizAttemptController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final StudentController _students = Get.find<StudentController>();

  late final String assessmentId;
  late final String subject;
  late final String assessmentTitle;

  final loading = true.obs;
  final submitting = false.obs;
  final RxnString error = RxnString();
  final questions = <dynamic>[].obs;
  final RxMap<String, dynamic> answers = <String, dynamic>{}.obs;
  final currentIndex = 0.obs;
  final RxnString attemptId = RxnString();
  final Rxn<Map<String, dynamic>> result = Rxn();

  String? get _studentId => _students.selectedStudent?.id;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    assessmentId = args['assessmentId'] as String? ?? '';
    subject = args['subject'] as String? ?? '';
    assessmentTitle = args['assessmentTitle'] as String? ?? subject;
    _start();
  }

  Future<void> _start() async {
    final studentId = _studentId;
    if (studentId == null) {
      error.value = 'No student selected';
      loading.value = false;
      return;
    }
    loading.value = true;
    error.value = null;
    try {
      final res = await _api.startQuiz(studentId, assessmentId: assessmentId, subject: subject);
      final attempt = Map<String, dynamic>.from(res['attempt'] as Map);
      attemptId.value = attempt['_id']?.toString();
      questions.value = (res['questions'] as List?) ?? [];
      // Resuming an in-progress attempt - pre-fill any answers already
      // saved on it so the student doesn't lose progress re-entering.
      for (final a in (attempt['answers'] as List? ?? [])) {
        final ans = Map<String, dynamic>.from(a as Map);
        final qid = ans['questionId']?.toString();
        if (qid == null) continue;
        if (ans['selectedOptionIndex'] != null) {
          answers[qid] = {'questionId': qid, 'selectedOptionIndex': ans['selectedOptionIndex']};
        } else if ((ans['textAnswer'] ?? '').toString().isNotEmpty) {
          answers[qid] = {'questionId': qid, 'textAnswer': ans['textAnswer']};
        }
      }
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'Could not load this quiz.';
    } finally {
      loading.value = false;
    }
  }

  Map<String, dynamic> get currentQuestion =>
      Map<String, dynamic>.from(questions[currentIndex.value] as Map);

  bool get isFirst => currentIndex.value == 0;
  bool get isLast => currentIndex.value == questions.length - 1;
  int get answeredCount => answers.length;

  bool isAnswered(String questionId) => answers.containsKey(questionId);

  void selectOption(String questionId, int optionIndex) {
    answers[questionId] = {'questionId': questionId, 'selectedOptionIndex': optionIndex};
  }

  void selectTrueFalse(String questionId, String value) {
    answers[questionId] = {'questionId': questionId, 'textAnswer': value};
  }

  void setTextAnswer(String questionId, String text) {
    if (text.trim().isEmpty) {
      answers.remove(questionId);
    } else {
      answers[questionId] = {'questionId': questionId, 'textAnswer': text};
    }
  }

  void next() {
    if (!isLast) currentIndex.value++;
  }

  void previous() {
    if (!isFirst) currentIndex.value--;
  }

  void jumpTo(int index) {
    if (index >= 0 && index < questions.length) currentIndex.value = index;
  }

  Future<bool> submit() async {
    final studentId = _studentId;
    final id = attemptId.value;
    if (studentId == null || id == null) return false;
    submitting.value = true;
    error.value = null;
    try {
      final payload = answers.values.map((a) => Map<String, dynamic>.from(a as Map)).toList();
      final res = await _api.submitQuiz(studentId, id, payload);
      result.value = Map<String, dynamic>.from(res);
      if (Get.isRegistered<QuizzesController>()) {
        Get.find<QuizzesController>().fetch();
      }
      return true;
    } on ApiException catch (e) {
      error.value = e.message;
      return false;
    } catch (_) {
      error.value = 'Could not submit this quiz. Please try again.';
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
