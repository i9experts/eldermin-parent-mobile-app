import 'package:get/get.dart';
import '../controllers/email_sign_in_controller.dart';

class EmailSignInBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmailSignInController());
  }
}
