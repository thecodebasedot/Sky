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
import 'services/encryption_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_incoming_call_service.dart';
import 'services/firebase_media_service.dart';
import 'services/conversation_cipher.dart';
import 'services/incoming_call_service.dart';
import 'services/firebase_notification_service.dart';
import 'services/firebase_public_key_directory.dart';
import 'services/media_service.dart';
import 'services/notification_service.dart';
import 'services/public_key_directory.dart';
import 'services/x25519_encryption_service.dart';
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

/// Selects the encryption backend based on [AppConfig]. Real E2E crypto on the
/// Firebase path; passthrough (plaintext) otherwise.
EncryptionService _buildEncryptionService() => AppConfig.useFirebase
    ? X25519EncryptionService()
    : PlaintextEncryptionService();

/// Selects the notification backend based on [AppConfig].
NotificationService _buildNotificationService() => AppConfig.useFirebase
    ? FirebaseNotificationService()
    : MockNotificationService();

/// Selects the public-key directory based on [AppConfig].
PublicKeyDirectory _buildPublicKeyDirectory() => AppConfig.useFirebase
    ? FirestorePublicKeyDirectory()
    : MockPublicKeyDirectory();

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
        Provider<EncryptionService>(create: (_) => _buildEncryptionService()),
        Provider<PublicKeyDirectory>(
          create: (_) => _buildPublicKeyDirectory(),
        ),
        Provider<NotificationService>(
          create: (_) => _buildNotificationService(),
        ),
        // ChatStore lives above the navigator so pushed screens can read it,
        // and follows the signed-in user via the AuthStore proxy.
        ChangeNotifierProxyProvider<AuthStore, ChatStore>(
          create: (context) => ChatStore(
            _buildChatRepository(),
            ConversationCipher(
              context.read<EncryptionService>(),
              context.read<PublicKeyDirectory>(),
            ),
          ),
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
      AuthStatus.authenticated => const _SignedInShell(),
      AuthStatus.needsProfile => const ProfileSetupScreen(),
      _ => const WelcomeScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(status), child: child),
    );
  }
}

/// Mounted while signed in: starts session-scoped services (push notification
/// registration) and hosts the incoming-call listener + home.
class _SignedInShell extends StatefulWidget {
  const _SignedInShell();

  @override
  State<_SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<_SignedInShell> {
  NotificationService? _notifications;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = context.read<AuthStore>().user?.id;
    _notifications = context.read<NotificationService>();
    final id = _userId;
    if (id != null) {
      _notifications!.init(id);
      _publishPublicKey(id);
    }
  }

  /// Publish this device's E2E public key so peers can encrypt to us.
  Future<void> _publishPublicKey(String userId) async {
    final encryption = context.read<EncryptionService>();
    final directory = context.read<PublicKeyDirectory>();
    final key = await encryption.publicKeyBase64();
    if (key.isNotEmpty) await directory.publish(userId, key);
  }

  @override
  void dispose() {
    final id = _userId;
    if (id != null) _notifications?.clear(id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const IncomingCallListener(child: HomeScreen());
  }
}
