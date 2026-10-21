import 'package:get/get.dart';
import '../../events/controllers/events_controller.dart';
import '../../messages/controllers/messages_controller.dart';
import '../../results/controllers/results_controller.dart';
import 'home_dashboard_controller.dart';

class HomeShellController extends GetxController {
  final tabIndex = 0.obs;

  /// The tabs live in an IndexedStack, so their controllers are built once
  /// and never re-run onInit; refresh the data-bearing ones whenever their
  /// tab is opened so new replies, unread flags and events show up.
  void changeTab(int index) {
    final changed = index != tabIndex.value;
    tabIndex.value = index;
    if (!changed) return;
    if (index == 0 && Get.isRegistered<HomeDashboardController>()) {
      Get.find<HomeDashboardController>().refresh();
    } else if (index == 1 && Get.isRegistered<ResultsController>()) {
      Get.find<ResultsController>().fetch();
    } else if (index == 2 && Get.isRegistered<EventsController>()) {
      Get.find<EventsController>().fetch();
    } else if (index == 3 && Get.isRegistered<MessagesController>()) {
      Get.find<MessagesController>().fetch();
    }
  }
}
