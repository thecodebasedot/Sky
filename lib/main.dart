import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'services/firebase_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only touch Firebase when explicitly enabled (see AppConfig). On Android &
  // iOS this reads the native google-services.json / GoogleService-Info.plist
  // added during `docs/FIREBASE_SETUP.md`.
  if (AppConfig.useFirebase) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(const SkyApp());
}
