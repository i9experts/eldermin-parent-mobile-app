import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/common/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'core/design/design.dart';
import 'core/theme/app_theme.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/modules/auth/views/phone_entry_screen.dart';
import 'app/modules/home/views/home_shell.dart';
import 'app/modules/splash/views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses(); // Plus Jakarta Sans (OFL), the app-wide font
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
      home: const AuthGate(),
    );
  }
}

/// Watches auth state and routes to the right root screen - never shows
/// the home shell without a valid session, and never gets stuck on a
/// splash screen once bootstrap resolves either way.
@visibleForTesting
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Worker? _worker;

  /// The animated splash stays on top of the next screen until its hand-off finished (the logo flies into
  /// the login screen's header, or fades out for the home shell).
  late bool _splashActive;

  bool _ready(AuthController auth) => auth.status.value != AuthStatus.unknown;

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();
    _splashActive = !_ready(auth);
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

  Widget _destination(AuthController auth) {
    switch (auth.status.value) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
        return const PhoneEntryScreen();
      case AuthStatus.authenticated:
        return const HomeShell();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final ready = _ready(auth);
      final toHeader = auth.status.value == AuthStatus.unauthenticated;
      // Always a Stack, destination first: when the overlay is removed the destination keeps its place in
      // the tree (re-parenting it would remount it and replay its entrance).
      final Widget base;
      if (ready) {
        base = _destination(auth);
      } else {
        // not resolved: the overlay is the splash; after the hand-off a plain one
        base = _splashActive ? const SizedBox.shrink() : const SplashScreen();
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          base,
          if (_splashActive)
            SplashScreen(
              ready: ready,
              flyToHeader: toHeader,
              onExited: () {
                if (mounted) setState(() => _splashActive = false);
              },
            ),
        ],
      );
    });
  }
}
