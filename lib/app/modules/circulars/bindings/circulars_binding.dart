import 'package:get/get.dart';
import '../controllers/circulars_controller.dart';

class CircularsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CircularsController());
  }
}
