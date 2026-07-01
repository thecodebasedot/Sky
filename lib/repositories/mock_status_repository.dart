import 'dart:async';

import 'package:uuid/uuid.dart';

import '../data/mock_data.dart';
import '../models/story.dart';
import '../models/user.dart';
import 'status_repository.dart';

/// In-memory [StatusRepository] seeded from [MockData]; posting prepends to the
/// current user's story and re-broadcasts.
class MockStatusRepository implements StatusRepository {
  MockStatusRepository() : _stories = MockData.stories();

  List<Story> _stories;
  final _controller = StreamController<List<Story>>.broadcast();
  final _uuid = const Uuid();

  @override
  Stream<List<Story>> watchStories(String userId) async* {
    yield _stories;
    yield* _controller.stream;
  }

  @override
  Future<void> postText(
    SkyUser me, {
    required String caption,
    required int colorValue,
  }) async {
    _addItem(
      me,
      StoryItem(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        caption: caption,
        backgroundColorValue: colorValue,
      ),
    );
  }

  @override
  Future<void> postImage(
    SkyUser me, {
    required String mediaUrl,
    String? caption,
  }) async {
    _addItem(
      me,
      StoryItem(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        imageUrl: mediaUrl,
        caption: caption,
      ),
    );
  }

  void _addItem(SkyUser me, StoryItem item) {
    final i = _stories.indexWhere((s) => s.user.id == me.id);
    if (i == -1) {
      _stories = [Story(user: me, items: [item]), ..._stories];
    } else {
      _stories[i] = Story(
        user: _stories[i].user,
        items: [..._stories[i].items, item],
      );
    }
    if (!_controller.isClosed) _controller.add(_stories);
  }

  @override
  void dispose() => _controller.close();
}
