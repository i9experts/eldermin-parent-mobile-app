import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/phone_entry_screen.dart';
import 'features/home/home_shell.dart';

/// Global navigator key so any part of the app (not just the screen
/// that triggered a login/logout) can clear the route stack when auth
/// state flips - covers both the OTP screen's own login flow AND a
/// future 401-triggered auto-logout from deep inside some other screen.
final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const ProviderScope(child: EldeminParentApp()));
}

class EldeminParentApp extends StatelessWidget {
  const EldeminParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eldermin Parent App',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

/// Watches auth state and routes to the right root screen - never shows
/// the home shell without a valid session, and never gets stuck on a
/// splash screen once bootstrap resolves either way.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Whenever auth status actually changes (login OR logout/401),
    // clear any pushed routes (e.g. the OTP screen, or some deep screen
    // open when a session expired) so the new root screen is what the
    // user actually sees, not hidden underneath a stale pushed route.
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.status != next.status) {
        rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    final authState = ref.watch(authStateProvider);

    switch (authState.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          backgroundColor: AppColors.navy,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      case AuthStatus.unauthenticated:
        return const PhoneEntryScreen();
      case AuthStatus.authenticated:
        return const HomeShell();
    }
  }
}

