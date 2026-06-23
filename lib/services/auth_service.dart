import '../models/user.dart';

/// Abstraction over the authentication backend.
///
/// Today this is fulfilled by [MockAuthService] so the app runs end-to-end
/// without external credentials. To go live, implement this interface with a
/// real provider (e.g. Firebase Auth phone sign-in or Supabase OTP) and swap
/// the instance passed to [AuthStore] — no UI changes required.
abstract class AuthService {
  /// Send a one-time verification code to [phoneNumber].
  Future<void> sendCode(String phoneNumber);

  /// Verify [code] for [phoneNumber].
  ///
  /// Returns the authenticated [SkyUser]. A freshly registered user comes back
  /// with an empty [SkyUser.name] so the UI can prompt for profile setup.
  Future<SkyUser> verifyCode(String phoneNumber, String code);

  /// Persist profile details after first sign-in.
  Future<SkyUser> completeProfile({
    required String userId,
    required String name,
    String? about,
  });

  /// Sign the current user out.
  Future<void> signOut();
}

/// Thrown when verification fails (wrong/expired code).
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// In-memory fake backend for local development and demos.
///
/// - Any 6-digit code is accepted; the demo code is `123456`.
/// - No data is persisted, so sign-in resets when the app restarts.
class MockAuthService implements AuthService {
  static const demoCode = '123456';

  @override
  Future<void> sendCode(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // A real backend would dispatch an SMS here.
  }

  @override
  Future<SkyUser> verifyCode(String phoneNumber, String code) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final digits = code.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) {
      throw AuthException('Enter the 6-digit code we sent you.');
    }
    // New user: empty name signals the UI to run profile setup.
    return SkyUser(
      id: 'me',
      name: '',
      phoneNumber: phoneNumber,
      isOnline: true,
    );
  }

  @override
  Future<SkyUser> completeProfile({
    required String userId,
    required String name,
    String? about,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return SkyUser(
      id: userId,
      name: name.trim(),
      about: (about == null || about.trim().isEmpty)
          ? 'Hey there! I am using Sky.'
          : about.trim(),
      isOnline: true,
    );
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
