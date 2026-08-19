import 'package:get/get.dart';
import '../controllers/dues_controller.dart';

class DuesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DuesController());
  }
}
