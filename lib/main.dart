import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/common/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'core/theme/app_theme.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/modules/auth/views/phone_entry_screen.dart';
import 'app/modules/home/views/home_shell.dart';
import 'app/modules/splash/views/splash_screen.dart';

void main() {
  runApp(const EldeminParentApp());
}

class EldeminParentApp extends StatelessWidget {
  const EldeminParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Eldermin Parent App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialBinding: InitialBinding(),
      getPages: AppPages.pages,
      home: const _AuthGate(),
    );
  }
}

/// Watches auth state and routes to the right root screen - never shows
/// the home shell without a valid session, and never gets stuck on a
/// splash screen once bootstrap resolves either way.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();
    // Whenever auth status actually changes (login OR logout/401), clear
    // any pushed routes (e.g. the OTP screen, or some deep screen open
    // when a session expired) so the new root screen is what the user
    // actually sees, not hidden underneath a stale pushed route.
    _worker = ever(auth.status, (_) {
      if (Get.key.currentState?.canPop() ?? false) {
        Get.until((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      switch (auth.status.value) {
        case AuthStatus.unknown:
          return const HomeShell();
        case AuthStatus.unauthenticated:
          return const HomeShell();
        case AuthStatus.authenticated:
          return const HomeShell();
      }
    });
  }
}
