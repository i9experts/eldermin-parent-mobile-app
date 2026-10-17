import 'package:get/get.dart';
import '../controllers/quiz_attempt_controller.dart';

class QuizAttemptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuizAttemptController());
  }
}
