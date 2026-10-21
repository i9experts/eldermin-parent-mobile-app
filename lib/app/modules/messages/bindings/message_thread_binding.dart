import 'package:get/get.dart';
import '../controllers/message_thread_controller.dart';

class MessageThreadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MessageThreadController());
  }
}
