import 'package:get/get.dart';
import '../controllers/tarbiyah_controller.dart';

class TarbiyahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TarbiyahController());
  }
}
