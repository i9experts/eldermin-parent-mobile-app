import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

class FeedbackController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();
  final AuthController _auth = Get.find<AuthController>();

  final priority = 'medium'.obs;
  final submitting = false.obs;
  final RxnString error = RxnString();

  Future<bool> submit({required String title, required String description}) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      error.value = 'Please fill in both a subject and description.';
      return false;
    }
    submitting.value = true;
    error.value = null;
    try {
      await _api.submitFeedback(
        title: title.trim(),
        description: description.trim(),
        raisedByName: _auth.userName.value ?? 'Parent',
        priority: priority.value,
      );
      return true;
    } catch (_) {
      error.value = 'Could not submit your feedback. Please try again.';
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
