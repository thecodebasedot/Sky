import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'media_service.dart';

/// Picks an image with image_picker and uploads it to Firebase Storage under
/// `chat_media/{chatId}/...`, returning the public download URL.
///
/// Requires the platform permission strings to be configured (see
/// `docs/FIREBASE_SETUP.md`). Used only when the app runs with
/// `--dart-define=USE_FIREBASE=true`.
class FirebaseMediaService implements MediaService {
  FirebaseMediaService({ImagePicker? picker, FirebaseStorage? storage})
      : _picker = picker ?? ImagePicker(),
        _storage = storage ?? FirebaseStorage.instance;

  final ImagePicker _picker;
  final FirebaseStorage _storage;

  @override
  Future<String?> pickAndUploadImage({
    required String chatId,
    required bool fromCamera,
  }) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return null;

    final fileName = picked.name.isEmpty
        ? 'image_${picked.hashCode}.jpg'
        : picked.name;
    final ref = _storage.ref('chat_media/$chatId/$fileName');

    final task = await ref.putFile(File(picked.path));
    return task.ref.getDownloadURL();
  }
}
