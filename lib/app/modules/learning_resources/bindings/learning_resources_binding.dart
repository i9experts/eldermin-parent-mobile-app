import 'package:get/get.dart';
import '../controllers/learning_resources_controller.dart';

class LearningResourcesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LearningResourcesController());
  }
}
