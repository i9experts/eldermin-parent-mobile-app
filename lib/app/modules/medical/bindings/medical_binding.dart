import 'package:get/get.dart';
import '../controllers/medical_controller.dart';

class MedicalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MedicalController());
  }
}
