import 'package:get/get.dart';
import '../../../core/network/base_client.dart';
import '../../../core/network/dio_service.dart';
import '../../../core/services/parent_api_service.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/students/controllers/student_controller.dart';

/// Wires up the app's global, app-lifetime singletons - the network layer
/// and the two pieces of state (session + selected child) every feature
/// depends on. Everything else is bound per-feature/per-route instead.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ParentApiService(BaseClient()), permanent: true);

    final auth = Get.put(AuthController(), permanent: true);
    DioService.onUnauthorized = auth.logout;

    Get.put(StudentController(Get.find<ParentApiService>()), permanent: true);
  }
}
