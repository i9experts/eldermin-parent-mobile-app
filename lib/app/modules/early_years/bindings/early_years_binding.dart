import 'package:get/get.dart';
import '../controllers/early_years_controller.dart';

/// The controller is permanent (registered in InitialBinding) because the "Early
/// Years" tile in More depends on it; this only guards a route opened without it.
class EarlyYearsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EarlyYearsController>()) Get.put(EarlyYearsController(), permanent: true);
  }
}
