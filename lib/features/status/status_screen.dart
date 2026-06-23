import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/story.dart';
import '../../state/chat_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar.dart';

/// The "Status" tab — your update plus recent ones from contacts.
class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = context.watch<ChatStore>().stories;
    final recent = stories.where((s) => !s.seen).toList();
    final viewed = stories.where((s) => s.seen).toList();

    return ListView(
      children: [
        _myStatus(context),
        const Divider(height: 1),
        if (recent.isNotEmpty) _sectionHeader(context, 'Recent updates'),
        ...recent.map((s) => _storyTile(context, s)),
        if (viewed.isNotEmpty) _sectionHeader(context, 'Viewed updates'),
        ...viewed.map((s) => _storyTile(context, s)),
      ],
    );
  }

  Widget _myStatus(BuildContext context) {
    return ListTile(
      leading: const Stack(
        children: [
          Avatar(user: MockData.me, radius: 24),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: AppTheme.skyBlue,
              child: Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
      title: const Text('My status',
          style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Tap to add status update'),
      onTap: () {},
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _storyTile(BuildContext context, Story story) {
    final ringColor = story.seen
        ? Theme.of(context).colorScheme.outlineVariant
        : AppTheme.skyBlue;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2.5),
        ),
        child: Avatar(user: story.user, radius: 21),
      ),
      title: Text(story.user.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(TimeFormat.relative(story.latest)),
      onTap: () => _openStory(context, story),
    );
  }

  void _openStory(BuildContext context, Story story) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _StoryViewer(story: story),
      ),
    );
  }
}

/// Full-screen, auto-advancing story viewer.
class _StoryViewer extends StatefulWidget {
  const _StoryViewer({required this.story});

  final Story story;

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  int _index = 0;

  void _next() {
    if (_index < widget.story.items.length - 1) {
      setState(() => _index++);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.story.items[_index];
    final bg = Color(item.backgroundColorValue ?? 0xFF1E88E5);

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        onTapUp: (details) {
          final w = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < w / 3) {
            _prev();
          } else {
            _next();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: List.generate(widget.story.items.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: i <= _index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              ListTile(
                leading: Avatar(user: widget.story.user, radius: 18),
                title: Text(
                  widget.story.user.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  TimeFormat.relative(item.timestamp),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      item.caption ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
