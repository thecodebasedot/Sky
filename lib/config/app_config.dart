/// Compile-time configuration for Sky.
///
/// The app ships wired to an in-memory mock backend so it runs with zero
/// setup. Once you've completed `docs/FIREBASE_SETUP.md`, run the app with
/// Firebase enabled:
///
/// ```bash
/// flutter run --dart-define=USE_FIREBASE=true
/// ```
class AppConfig {
  AppConfig._();

  /// When true, the app uses Firebase Auth + Cloud Firestore. When false
  /// (default), it uses the local mock services and sample data.
  static const bool useFirebase =
      bool.fromEnvironment('USE_FIREBASE', defaultValue: false);
}
