import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story.dart';
import '../models/user.dart';
import 'status_repository.dart';

/// Cloud Firestore implementation of [StatusRepository].
///
/// Layout: `statuses/{userId}` with a denormalized `user` map and an `items`
/// array of `{id, imageUrl?, caption?, backgroundColorValue?, timestamp}`.
/// `updatedAt` drives ordering; items older than 24h are filtered on read.
class FirestoreStatusRepository implements StatusRepository {
  FirestoreStatusRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _statuses =>
      _db.collection('statuses');

  @override
  Stream<List<Story>> watchStories(String userId) {
    // Surface updates from the last 24h. (A production build would scope this
    // to the user's contacts; here it streams all recent statuses.)
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );
    return _statuses
        .where('updatedAt', isGreaterThan: cutoff)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(_storyFromDoc)
            .where((s) => s.items.isNotEmpty)
            .toList());
  }

  @override
  Future<void> postText(
    SkyUser me, {
    required String caption,
    required int colorValue,
  }) {
    return _append(me, {
      'id': _id(),
      'caption': caption,
      'backgroundColorValue': colorValue,
      'timestamp': Timestamp.now(),
    });
  }

  @override
  Future<void> postImage(
    SkyUser me, {
    required String mediaUrl,
    String? caption,
  }) {
    return _append(me, {
      'id': _id(),
      'imageUrl': mediaUrl,
      if (caption != null) 'caption': caption,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _append(SkyUser me, Map<String, dynamic> item) {
    return _statuses.doc(me.id).set({
      'user': {
        'id': me.id,
        'name': me.name,
        'avatarUrl': me.avatarUrl,
      },
      'items': FieldValue.arrayUnion([item]),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  String _id() => _statuses.doc().id;

  Story _storyFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final userMap = Map<String, dynamic>.from(data['user'] as Map? ?? {});
    final user = SkyUser(
      id: userMap['id'] as String? ?? doc.id,
      name: userMap['name'] as String? ?? 'Unknown',
      avatarUrl: userMap['avatarUrl'] as String?,
    );

    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final items = (data['items'] as List? ?? [])
        .map((raw) => _itemFromMap(Map<String, dynamic>.from(raw as Map)))
        .where((i) => i.timestamp.isAfter(cutoff))
        .toList();

    return Story(user: user, items: items);
  }

  StoryItem _itemFromMap(Map<String, dynamic> m) {
    return StoryItem(
      id: m['id'] as String? ?? '',
      timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: m['imageUrl'] as String?,
      caption: m['caption'] as String?,
      backgroundColorValue: (m['backgroundColorValue'] as num?)?.toInt(),
    );
  }

  @override
  void dispose() {}
}
