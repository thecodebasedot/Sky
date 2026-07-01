import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/calls/incoming_call_listener.dart';
import 'features/home/home_screen.dart';
import 'repositories/chat_repository.dart';
import 'repositories/firestore_chat_repository.dart';
import 'repositories/firestore_status_repository.dart';
import 'repositories/mock_chat_repository.dart';
import 'repositories/mock_status_repository.dart';
import 'repositories/status_repository.dart';
import 'services/auth_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_incoming_call_service.dart';
import 'services/firebase_media_service.dart';
import 'services/incoming_call_service.dart';
import 'services/media_service.dart';
import 'state/auth_store.dart';
import 'state/chat_store.dart';
import 'state/status_store.dart';
import 'theme/app_theme.dart';

/// Selects the auth backend based on [AppConfig].
AuthService _buildAuthService() =>
    AppConfig.useFirebase ? FirebaseAuthService() : MockAuthService();

/// Selects the messaging backend based on [AppConfig].
ChatRepository _buildChatRepository() =>
    AppConfig.useFirebase ? FirestoreChatRepository() : MockChatRepository();

/// Selects the media backend based on [AppConfig].
MediaService _buildMediaService() =>
    AppConfig.useFirebase ? FirebaseMediaService() : MockMediaService();

/// Selects the incoming-call backend based on [AppConfig].
IncomingCallService _buildIncomingCallService() => AppConfig.useFirebase
    ? FirebaseIncomingCallService()
    : MockIncomingCallService();

/// Selects the status backend based on [AppConfig].
StatusRepository _buildStatusRepository() => AppConfig.useFirebase
    ? FirestoreStatusRepository()
    : MockStatusRepository();

/// Root widget: provides app-wide state and theming.
class SkyApp extends StatelessWidget {
  const SkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore(_buildAuthService())),
        Provider<MediaService>(create: (_) => _buildMediaService()),
        Provider<IncomingCallService>(
          create: (_) => _buildIncomingCallService(),
        ),
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
        ChangeNotifierProxyProvider<AuthStore, StatusStore>(
          create: (_) => StatusStore(_buildStatusRepository()),
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
      AuthStatus.authenticated =>
        const IncomingCallListener(child: HomeScreen()),
      AuthStatus.needsProfile => const ProfileSetupScreen(),
      _ => const WelcomeScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(status), child: child),
    );
  }
}
