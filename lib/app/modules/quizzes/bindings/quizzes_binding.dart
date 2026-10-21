import 'package:get/get.dart';
import '../controllers/quiz_attempt_controller.dart';
import '../controllers/quizzes_controller.dart';

class QuizzesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuizzesController());
  }
}

class QuizAttemptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuizAttemptController());
  }
}
