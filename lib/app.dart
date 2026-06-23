import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/home/home_screen.dart';
import 'repositories/chat_repository.dart';
import 'repositories/firestore_chat_repository.dart';
import 'repositories/mock_chat_repository.dart';
import 'services/auth_service.dart';
import 'services/firebase_auth_service.dart';
import 'state/auth_store.dart';
import 'state/chat_store.dart';
import 'theme/app_theme.dart';

/// Selects the auth backend based on [AppConfig].
AuthService _buildAuthService() =>
    AppConfig.useFirebase ? FirebaseAuthService() : MockAuthService();

/// Selects the messaging backend based on [AppConfig].
ChatRepository _buildChatRepository() =>
    AppConfig.useFirebase ? FirestoreChatRepository() : MockChatRepository();

/// Root widget: provides app-wide state and theming.
class SkyApp extends StatelessWidget {
  const SkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore(_buildAuthService())),
        // ChatStore lives above the navigator so pushed screens can read it,
        // and follows the signed-in user via the AuthStore proxy.
        ChangeNotifierProxyProvider<AuthStore, ChatStore>(
          create: (_) => ChatStore(_buildChatRepository()),
          update: (_, auth, store) {
            store!.bind(
              auth.status == AuthStatus.authenticated ? auth.user?.id : null,
            );
            return store;
          },
        ),
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(status), child: child),
    );
  }
}
