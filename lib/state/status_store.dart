import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/story.dart';
import '../models/user.dart';
import '../repositories/status_repository.dart';

/// App state for status updates, backed by a [StatusRepository].
class StatusStore extends ChangeNotifier {
  StatusStore(this._repo);

  final StatusRepository _repo;

  List<Story> _stories = const [];
  String? _myId;
  StreamSubscription<List<Story>>? _sub;
  bool _disposed = false;

  List<Story> get stories => _stories;

  /// Stories from other people (not the signed-in user).
  List<Story> othersStories(String myId) =>
      _stories.where((s) => s.user.id != myId).toList();

  /// The signed-in user's own story, if any.
  Story? myStory(String myId) {
    for (final s in _stories) {
      if (s.user.id == myId) return s;
    }
    return null;
  }

  void bind(String? userId) {
    if (userId == _myId) return;
    _myId = userId;
    _sub?.cancel();
    _stories = const [];
    if (userId != null) {
      _sub = _repo.watchStories(userId).listen((s) {
        _stories = s;
        notifyListeners();
      });
    }
    Future.microtask(() {
      if (!_disposed) notifyListeners();
    });
  }

  Future<void> postText(SkyUser me, String caption, int colorValue) =>
      _repo.postText(me, caption: caption, colorValue: colorValue);

  Future<void> postImage(SkyUser me, String mediaUrl, {String? caption}) =>
      _repo.postImage(me, mediaUrl: mediaUrl, caption: caption);

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _repo.dispose();
    super.dispose();
  }
}
