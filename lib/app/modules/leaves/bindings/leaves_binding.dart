import 'package:get/get.dart';
import '../controllers/leaves_controller.dart';

class LeavesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LeavesController());
  }
}
