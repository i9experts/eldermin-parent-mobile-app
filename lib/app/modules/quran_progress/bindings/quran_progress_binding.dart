import 'package:get/get.dart';
import '../controllers/quran_progress_controller.dart';

class QuranProgressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuranProgressController());
  }
}
