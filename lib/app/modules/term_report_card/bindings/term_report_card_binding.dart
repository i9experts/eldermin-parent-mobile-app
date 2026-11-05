import 'package:get/get.dart';
import '../controllers/term_report_card_controller.dart';

class TermReportCardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TermReportCardController());
  }
}
