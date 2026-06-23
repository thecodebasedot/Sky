# Firebase setup

Sky runs on a local **mock backend** by default. Follow these steps once to
connect it to a real Firebase project so two devices can actually message each
other. Everything here is one-time setup; afterwards you just run with the
`USE_FIREBASE` flag on.

> You'll need a Google account and the Flutter SDK already working
> (`flutter doctor` is clean).

---

## 1. Create the Firebase project
1. Go to the [Firebase console](https://console.firebase.google.com) →
   **Add project**. Name it e.g. `sky-app`.
2. In the project, open **Build → Authentication → Get started** and enable the
   **Phone** sign-in provider.
   - While testing, add a few **test phone numbers** (Authentication → Sign-in
     method → Phone → *Phone numbers for testing*) so you don't burn real SMS.
3. Open **Build → Firestore Database → Create database** (start in *production
   mode*; we deploy rules below).

## 2. Install the tooling
```bash
# Firebase CLI
npm install -g firebase-tools
firebase login

# FlutterFire CLI
dart pub global activate flutterfire_cli
```

## 3. Wire the apps to the project
From the repo root:
```bash
flutterfire configure
```
Select your `sky-app` project and the platforms (Android, iOS). This generates
`lib/firebase_options.dart` **and** adds the native config files
(`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) plus
the required Gradle/Pod wiring.

> Sky calls `Firebase.initializeApp()` with no arguments, which picks up these
> native config files automatically — no extra code needed.

> **iOS:** Firebase requires a minimum deployment target of **iOS 13**. If the
> Pod install complains, set `platform :ios, '13.0'` in `ios/Podfile` and
> `IPHONEOS_DEPLOYMENT_TARGET = 13.0` in the Runner target, then
> `cd ios && pod install`.

## 4. Deploy the security rules
The repo ships with `firestore.rules` (participants-only access) and
`storage.rules` (signed-in image uploads). Deploy them:
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage          # requires Storage enabled in the console
```
You may also want a composite index for the chats query. If the app logs a
"requires an index" link at runtime, click it to auto-create the index for
`chats` on `participantIds (array-contains) + updatedAt (desc)`.

### Media uploads (photos)
Photo sharing uses `image_picker` + Firebase Storage. Enable **Build → Storage**
in the Firebase console, then add the platform permission strings:

- **iOS** (`ios/Runner/Info.plist`):
  - `NSPhotoLibraryUsageDescription` — "Sky needs access to your photos to share them."
  - `NSCameraUsageDescription` — "Sky needs camera access to take photos."
- **Android**: gallery needs no extra permission; the camera uses
  `image_picker`'s bundled `CAMERA` declaration. No manual changes required for
  typical use.

On the mock backend, "Gallery"/"Camera" just attach a sample image — no
permissions needed.

### Calls (WebRTC)
Voice/video calls use `flutter_webrtc` with **Firestore as the signaling
channel** (offer/answer/ICE under `calls/{callId}`; rules included in
`firestore.rules`). Add the platform permissions:

- **iOS** (`ios/Runner/Info.plist`): `NSCameraUsageDescription`,
  `NSMicrophoneUsageDescription`. Min iOS 13.
- **Android** (`android/app/src/main/AndroidManifest.xml`):
  `CAMERA`, `RECORD_AUDIO`, `INTERNET`, plus `MODIFY_AUDIO_SETTINGS`.
  `minSdkVersion` ≥ 23.

> ⚠️ **Device-bound & not yet complete for production.** The caller flow
> (place a call → offer → apply answer → exchange ICE) is implemented and must
> be verified on **two physical devices**. Still to wire for real-world use:
> the **incoming-call listener** (so the callee's device rings — watch `calls`
> where `calleeId == myUid` and present the call screen as callee), and a
> **TURN server** for calls that can't traverse NAT (STUN alone isn't enough on
> many networks). On the mock backend, calls are fully simulated — no
> permissions or devices needed.

## 5. Run with Firebase enabled
```bash
flutter pub get
flutter run --dart-define=USE_FIREBASE=true
```
Sign in with a test phone number and the code you configured in step 1.

---

## Data model (created automatically as you use the app)

```
users/{uid}
  id, name, phoneNumber, about, avatarUrl, updatedAt

chats/{chatId}
  participantIds: [uid, ...]      ← drives the "my chats" query + rules
  participants:   [{id,name,phoneNumber,avatarUrl,about}, ...]
  isGroup, name, avatarUrl
  lastMessage:    {text, type, senderId, timestamp}
  unreadCounts:   {uid: int, ...}
  updatedAt:      Timestamp

chats/{chatId}/messages/{messageId}
  senderId, text, type, status, timestamp, mediaUrl?, durationSeconds?
```

> **Note:** creating chats and a contact picker are upcoming work. The current
> Firestore repository reads/streams chats and sends messages; seeding the first
> conversations (or building the "new chat" flow) is the next task on the
> messaging milestone.

## Switching back to mock
Just run without the flag (`flutter run`). No Firebase config is touched.
