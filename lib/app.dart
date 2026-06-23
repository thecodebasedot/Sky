import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/profile_setup_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/home/home_screen.dart';
import 'services/auth_service.dart';
import 'state/auth_store.dart';
import 'state/chat_store.dart';
import 'theme/app_theme.dart';

/// Root widget: provides app-wide state and theming.
class SkyApp extends StatelessWidget {
  const SkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore(MockAuthService())),
        ChangeNotifierProvider(create: (_) => ChatStore()),
      ],
      child: MaterialApp(
        title: 'Sky',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Routes between the auth flow and the main app based on [AuthStatus].
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthStore>().status;

    final Widget child = switch (status) {
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.needsProfile => const ProfileSetupScreen(),
      _ => const WelcomeScreen(),
    };

    // Cross-fade between top-level destinations as auth state changes.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(
        key: ValueKey(status),
        child: child,
      ),
    );
  }
}
