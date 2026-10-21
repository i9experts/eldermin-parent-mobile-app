import 'package:get/get.dart';
import '../controllers/home_tasks_controller.dart';

class HomeTasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeTasksController());
  }
}
