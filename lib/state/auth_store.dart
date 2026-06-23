import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  /// Signed out — show the welcome / phone-entry flow.
  unauthenticated,

  /// Code dispatched — awaiting OTP entry.
  codeSent,

  /// Verified but no profile yet — show profile setup.
  needsProfile,

  /// Fully signed in.
  authenticated,
}

/// Owns authentication state and the signed-in [SkyUser] profile.
class AuthStore extends ChangeNotifier {
  AuthStore(this._service);

  final AuthService _service;

  AuthStatus _status = AuthStatus.unauthenticated;
  SkyUser? _user;
  String? _phoneNumber;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  SkyUser? get user => _user;
  String? get phoneNumber => _phoneNumber;
  String? get error => _error;
  bool get busy => _busy;

  /// Send a verification code and advance to the OTP step.
  Future<void> sendCode(String phoneNumber) async {
    _phoneNumber = phoneNumber;
    await _run(() async {
      await _service.sendCode(phoneNumber);
      _status = AuthStatus.codeSent;
    });
  }

  /// Verify the entered [code].
  Future<void> verifyCode(String code) async {
    final phone = _phoneNumber;
    if (phone == null) return;
    await _run(() async {
      final user = await _service.verifyCode(phone, code);
      _user = user;
      _status =
          user.name.isEmpty ? AuthStatus.needsProfile : AuthStatus.authenticated;
    });
  }

  /// Save profile details for a first-time user and finish sign-in.
  Future<void> completeProfile({required String name, String? about}) async {
    final id = _user?.id ?? 'me';
    await _run(() async {
      _user = await _service.completeProfile(
        userId: id,
        name: name,
        about: about,
      );
      _status = AuthStatus.authenticated;
    });
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    _phoneNumber = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Locally update the profile (e.g. from the settings screen).
  void updateProfile({String? name, String? about}) {
    final u = _user;
    if (u == null) return;
    _user = SkyUser(
      id: u.id,
      name: name ?? u.name,
      phoneNumber: u.phoneNumber,
      avatarUrl: u.avatarUrl,
      about: about ?? u.about,
      isOnline: u.isOnline,
      lastSeen: u.lastSeen,
    );
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Run an async action with busy/error bookkeeping and a single notify.
  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
